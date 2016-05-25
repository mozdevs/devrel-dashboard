module Bugzilla exposing (Model, Msg, update, view, init)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (id, class, attribute, target, href, title, classList, type', checked)
import Html.Events exposing (onClick, onCheck)
import Http
import Json.Decode exposing ((:=), Decoder, at, andThen, int, list, string, maybe, object3, succeed)
import Json.Decode.Extra exposing ((|:), dict2)
import Regex
import String
import Task


-- MODEL


type alias Model =
  { bugs : Dict Int Bug
  , sort : (SortField, SortDir)
  , showClosed : Bool
  }


init : (Model, Cmd Msg)
init =
  (,)
    { bugs = Dict.empty
    , sort = (ProductComponent, Asc)
    , showClosed = True
    }
    fetch


-- TYPES


type alias Bug =
  { id : Int
  , summary : String
  , product : String
  , component : String
  , state : Maybe State
  , priority: Maybe Priority
  , open : Bool
  }


type State
  = Unconfirmed
  | New
  | Assigned
  | Reopened
  | Resolved Resolution
  | Verified Resolution


type Resolution
  = Fixed
  | Invalid
  | WontFix
  | Duplicate Int
  | WorksForMe
  | Incomplete


type Priority
  = P1
  | P2
  | P3
  | PX


type SortField
  = Id
  | ProductComponent
  | Status


type SortDir
  = Asc
  | Desc


-- UPDATE


type Msg
  = FetchOk (Dict Int Bug)
  | FetchFail Http.Error
  | SortBy SortField
  | ToggleShowClosed


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchFail _ ->
      (model, Cmd.none)

    FetchOk bugs ->
      ({ model | bugs = bugs }, Cmd.none)

    SortBy field ->
      let
        (curField, curDir) =
          model.sort

        toggle direction =
          case direction of
            Asc ->
              Desc

            Desc ->
              Asc
      in
        if field == curField then
          ({ model | sort = (field, toggle curDir) }, Cmd.none)
        else
          ({ model | sort = (field, Asc) }, Cmd.none)

    ToggleShowClosed ->
      ({ model | showClosed = not model.showClosed }, Cmd.none)


-- VIEW


view : Model -> Html Msg
view model =
  let
    sortWidget : (SortField, String) -> Html Msg
    sortWidget (field, label) =
      button
        [ onClick <| SortBy field
        , classList
            [ ("as-text", True)
            , ("active", field == fst model.sort)
            , ("sort-asc", model.sort == (field, Asc))
            , ("sort-desc", model.sort == (field, Desc))
            ]
        ]
        [ text label ]

    closedWidget =
      label
        []
        [ input
            [ type' "checkbox"
            , checked model.showClosed
            , onCheck <| always ToggleShowClosed
            ]
            []
        , text "Show Closed Bugs"
        ]

    sortBar =
      div
        [ id "sort-bar"  ]
        [ closedWidget
        , div
            []
            ( [ (Id, "Bug Number")
              , (ProductComponent, "Product / Component")
              , (Status, "Status")
              ]
              |> List.map sortWidget
              |> List.intersperse (text ", ")
              |> (::) (text "Sort by: ")
            )
        ]
  in
    div
      [ id "bugs" ]
      [ sortBar
      , ul
          [ id "bugs" ]
          ( List.map (\bug -> li [] [viewBug bug])
              <| sortBugs model.sort
              <| List.filter (\bug -> bug.open || model.showClosed)
              <| Dict.values model.bugs
          )
      ]


sortBugs : (SortField, SortDir) -> List Bug -> List Bug
sortBugs (field, direction) bugs =
  let
    statusOrd state =
      case state of
        Nothing -> 0

        Just Unconfirmed -> 1
        Just New -> 1
        Just Reopened -> 1

        Just Assigned -> 2

        Just (Resolved (Duplicate _)) -> 3
        Just (Verified (Duplicate _)) -> 3

        Just (Resolved Fixed) -> 4
        Just (Verified Fixed) -> 4

        Just (Resolved Incomplete) -> 5
        Just (Verified Incomplete) -> 5

        Just (Resolved Invalid) -> 6
        Just (Verified Invalid) -> 6

        Just (Resolved WontFix) -> 7
        Just (Verified WontFix) -> 7

        Just (Resolved WorksForMe) -> 8
        Just (Verified WorksForMe) -> 8

    fn =
      case field of
        Id ->
          List.sortBy .id

        ProductComponent ->
          List.sortBy (\x -> (x.product, x.component, x.summary))

        Status ->
          List.sortBy (statusOrd << .state)
  in
     fn bugs
       |> if direction == Desc then List.reverse else identity


viewBug : Bug -> Html Msg
viewBug bug =
  let
    bugUrl =
      "https://bugzilla.mozilla.org/show_bug.cgi?id=" ++ (toString bug.id)

    stateString =
      case bug.state of
        Just (Resolved (Duplicate _)) ->
          "Duplicate"

        Just (Verified (Duplicate _)) ->
          "Duplicate"

        Just (Resolved resolution) ->
          toString resolution

        Just (Verified resolution) ->
          toString resolution

        Just Assigned ->
          "Assigned"

        Just New ->
          ""

        Just Unconfirmed ->
          ""

        Just Reopened ->
          ""

        Nothing ->
          "(Unknown Status)"

    prioString =
      Maybe.withDefault "Untriaged" (Maybe.map toString bug.priority)

    pcString =
      bug.product ++ " :: " ++ bug.component
  in
    div
      [ class "bug"
      , attribute "data-open" (toString bug.open)
      , attribute "data-status" stateString
      , attribute "data-priority" prioString
      ]
      [ div
          [ class "bug-header" ]
          [ div
              [ class "oneline", title pcString ]
              [ text pcString ]
          , a
              [ target "_blank", href bugUrl ]
              [ text <| "#" ++ (toString bug.id) ]
          ]
      , div
          [ class "bug-body" ]
          [ strong [] [ text bug.summary ] ]
      ]


-- HTTP


fetch : Cmd Msg
fetch =
  let
    url =
      Http.url
        -- "https://bugzilla.mozilla.org/rest/bug"
        "http://localhost:3000/db"
        [ (,) "keywords" "DevAdvocacy"
        , (,)
            "include_fields"
            (String.join ","
              [ "id"
              , "summary"
              , "status"
              , "resolution"
              , "dupe_of"
              , "product"
              , "component"
              , "whiteboard"
              ])
        ]
  in
    Task.perform FetchFail FetchOk (Http.get bugDecoder url)


-- JSON


bugDecoder : Decoder (Dict Int Bug)
bugDecoder =
  let
    asTuple : Bug -> (Int, Bug)
    asTuple bug = (bug.id, bug)

    toDict : List Bug -> Dict Int Bug
    toDict bugs =
      Dict.fromList << List.map asTuple <| bugs
  in
    at ["bugs"] (list decBug)
      |> Json.Decode.map toDict


decBug : Decoder Bug
decBug =
  succeed Bug
    |: ("id" := int)
    |: ("summary" := string)
    |: ("product" := string)
    |: ("component" := string)
    |: andThen -- "state"
         (object3 (,,)
           ("status" := string)
           ("resolution" := string)
           ("dupe_of" := maybe int))
         decState
    |: andThen -- "priority"
         ("whiteboard" := string)
         decPrio
    |: andThen -- "open"
         ("status" := string)
         decOpen


decState : (String, String, Maybe Int) -> Decoder (Maybe State)
decState (status, resolution, dupeOf) =
  let
    resolution' =
      case resolution of
        "FIXED" ->
          Just Fixed

        "INVALID" ->
          Just Invalid

        "WONTFIX" ->
          Just WontFix

        "DUPLICATE" ->
          Maybe.map (\id -> Duplicate id) dupeOf

        "WORKSFORME" ->
          Just WorksForMe

        "INCOMPLETE" ->
          Just Incomplete

        _ ->
          Nothing

    state =
      case status of
        "UNCONFIRMED" ->
          Just Unconfirmed

        "NEW" ->
          Just New

        "ASSIGNED" ->
          Just Assigned

        "REOPENED" ->
          Just Reopened

        "RESOLVED" ->
          Maybe.map (\x -> Resolved x) resolution'

        "VERIFIED" ->
          Maybe.map (\x -> Verified x) resolution'

        _ ->
          Nothing
  in
    succeed state


decPrio : String -> Decoder (Maybe Priority)
decPrio whiteboard =
  let
    pattern =
      Regex.regex "\\[devrel:p(.)\\]"

    matches =
      Regex.find (Regex.AtMost 1) pattern (String.toLower whiteboard)

    submatches =
      List.map (\x -> x.submatches) matches

    priority =
      case submatches of
        [Just "1" :: _] -> Just P1
        [Just "2" :: _] -> Just P2
        [Just "3" :: _] -> Just P3
        [Just "x" :: _] -> Just PX
        _ -> Nothing
  in
    succeed priority

decOpen : String -> Decoder Bool
decOpen status =
  succeed (status /= "RESOLVED" && status /= "VERIFIED")

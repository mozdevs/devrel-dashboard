-- module Bugzilla exposing (Model, Msg, update, view, init)
module Bugzilla exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (id, class, attribute, target, href, title, classList, type', checked, value, placeholder)
import Html.Events exposing (onClick, onCheck, onInput)
import Http
import Json.Decode exposing ((:=), Decoder, at, andThen, int, list, string, maybe, object3, succeed)
import Json.Decode.Extra exposing ((|:), dict2)
import Regex
import Set
import String
import Task


-- MODEL


type alias Model =
  { bugs : Dict Int Bug
  , sort : (SortField, SortDir)
  , showClosed : Bool
  , showPriorities : List (Maybe Priority)
  , filterText : String
  , networkStatus : Network
  }


init : (Model, Cmd Msg)
init =
  (,)
    { bugs = Dict.empty
    , sort = (ProductComponent, Asc)
    , showClosed = False
    , showPriorities = [ Just P1 ]
    , filterText = ""
    , networkStatus = Fetching
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
  | Priority


type SortDir
  = Asc
  | Desc


type Network
  = Fetching
  | Loaded
  | Failed


-- UPDATE


type Msg
  = FetchOk (Dict Int Bug)
  | FetchFail Http.Error
  | SortBy SortField
  | ToggleShowClosed
  | TogglePriority (Maybe Priority)
  | FilterText String


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchFail _ ->
      ({ model | networkStatus = Failed }, Cmd.none)

    FetchOk bugs ->
      ({ model | bugs = bugs, networkStatus = Loaded }, Cmd.none)

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

    TogglePriority priority ->
      let
        newPriorities =
          if List.member priority model.showPriorities then
            List.filter ((/=) priority) model.showPriorities
          else
            priority :: model.showPriorities
      in
      ({ model | showPriorities = newPriorities }, Cmd.none)

    FilterText s ->
      ({ model | filterText = s }, Cmd.none)


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

    prioWidget (priority, labelText, meaning) =
      let
        prioString =
          Maybe.withDefault "Untriaged" (Maybe.map toString priority)
      in
        label
          [ class "priority-widget"
          , title <| labelText ++ "—" ++ meaning
          ]
          [ input
              [ type' "checkbox" 
              , checked (List.member priority model.showPriorities)
              , onCheck <| always (TogglePriority priority)
              ]
              []
          , if meaning /= "" then
               abbr
                 [ class <| String.toLower ("priority-filter-" ++ prioString)
                 , title <| labelText ++ "—" ++ meaning
                 ]
                 [ text labelText ]
            else
               span
                 [ class <| String.toLower ("priority-filter-" ++ prioString) ]
                 [ text labelText ]
          ]

    sortBar =
      div
        [ id "sort-bar"  ]
        [ input
            [ class "filter-products"
            , attribute "list" "datalist-products"
            , placeholder "Filter Bugs"
            , onInput FilterText
            ]
            []
        , datalist
            [ id "datalist-products" ]
            ( model.bugs
              |> Dict.values
              |> List.map (\bug -> [bug.product, bug.product ++ " :: " ++ bug.component])
              |> List.concat
              |> Set.fromList
              |> Set.toList
              |> List.map (\product -> option [ value product ] [])
            )
        , div
            [ class "filter-priorities" ]
            ( [ (Just P1, "P1", "Critical")
              , (Just P2, "P2", "Major")
              , (Just P3, "P3", "Minor")
              , (Just PX, "PX", "Ignore")
              , (Nothing, "Untriaged", "")
              ]
                |> List.map prioWidget
                |> List.intersperse (text ", ")
                |> (::) (text "Priorities: ")
            )
        , closedWidget
        , div
            []
            ( [ (Id, "Number")
              , (ProductComponent, "Product / Component")
              , (Status, "Status")
              , (Priority, "Priority")
              ]
              |> List.map sortWidget
              |> List.intersperse (text ", ")
              |> (::) (text "Sort: ")
            )
        ]

    matchesFilterText bug =
      List.any
        (String.contains <| String.toLower model.filterText)
        [ String.toLower (bug.product ++ " :: " ++ bug.component)
        , String.toLower bug.summary
        ]

    matchesPriority bug =
      List.isEmpty model.showPriorities || List.member bug.priority model.showPriorities

    matchesShowOpen bug =
      bug.open || model.showClosed
  in
    div
      [ class "bugs" ]
      [ sortBar
      , case model.networkStatus of
          Fetching ->
            div [ class "loading" ] [ text "Fetching data from Bugilla..." ]

          Failed ->
            div [ class "loading-error" ] [ text "Error fetching data. Please refresh." ]

          Loaded ->
            ul
              []
              ( List.map (\bug -> li [] [viewBug bug])
                  <| sortBugs model.sort
                  <| List.filter matchesFilterText
                  <| List.filter matchesPriority
                  <| List.filter matchesShowOpen
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

    prioOrd priority =
      case priority of
        Just P1 -> 1
        Just P2 -> 2
        Just P3 -> 3
        Just PX -> 4
        Nothing -> 5

    fn =
      case field of
        Id ->
          List.sortBy .id

        ProductComponent ->
          List.sortBy (\x -> (x.product, x.component, x.summary))

        Status ->
          List.sortBy (\x -> (statusOrd x.state, x.product, x.component, x.summary))

        Priority ->
          List.sortBy (\x -> (prioOrd x.priority, x.product, x.component, x.summary))
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
        -- "http://localhost:3000/db"
        "https://bugzilla.mozilla.org/rest/bug"
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
    Task.perform FetchFail FetchOk
      <| Http.fromJson bugDecoder
      <| Http.send
           Http.defaultSettings
           { verb = "GET"
           , headers = [("Accept", "application/json")]
           , url = url
           , body = Http.empty
           }

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

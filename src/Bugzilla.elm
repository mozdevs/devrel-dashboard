module Bugzilla exposing (Model, Msg, update, view, init)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (..)
import Regex exposing (..)
import String exposing (..)
import Task


-- MODEL

type alias Model =
  List Bug

init : (Model, Cmd Msg)
init =
  ([], fetch)

type alias Bug =
  { id : Int
  , summary : String
  , status : Status
  , priority : Priority
  , product : String
  , component : String
  }

type Status
  = Unconfirmed
  | New
  | Assigned
  | Reopened
  | Resolved Resolution
  | Verified Resolution
  | UnknownStatus

type Resolution
  = Fixed
  | Invalid
  | WontFix
  | Duplicate Int
  | WorksForMe
  | Incomplete
  | UnknownResolution

type Priority
  = P1
  | P2
  | P3
  | PX
  | Untriaged


-- UPDATE

type Msg
  = FetchOk (List Bug)
  | FetchFail Http.Error

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchFail _ ->
      (model, Cmd.none)
    FetchOk bugs ->
      (bugs, Cmd.none)


-- VIEW

view : Model -> Html Msg
view model =
  div
    []
    (List.map viewBug model)

viewBug : Bug -> Html Msg
viewBug bug =
  let
    prodComp =
      bug.product ++ " :: " ++ bug.component
  in
    div
      [ class "bug"
      , attribute "data-open" (toString <| bugOpen bug)
      , attribute "data-status" (bugStatus bug)
      ]
      [ div
          [ class "bug-header" ]
          [ span [ class "bug-prodcomp", title prodComp ] [ text prodComp ]
          , bugLink [ class "bug-id" ] bug ("#" ++ (toString bug.id))
          ]
      , bugLink [ class "bug-summary" ] bug bug.summary
      ]

bugLink : List (Html.Attribute Msg) -> Bug -> String -> Html Msg
bugLink attrs bug label =
  let
    url =
      "https://bugzilla.mozilla.org/show_bug.cgi?id=" ++ (toString bug.id)
  in
    a
      ([ href url
       , target "_blank"
       , title (bugStatus bug ++ ": " ++ bug.summary)
       ] ++ attrs)
      [ text label ]

bugStatus : Bug -> String
bugStatus bug =
  case bug.status of
    New -> "NEW"
    Unconfirmed -> "NEW"
    Assigned -> "ASSIGNED"
    Reopened -> "REOPENED"
    Resolved Fixed -> "FIXED"
    Resolved Invalid -> "INVALID"
    Resolved WontFix -> "WONTFIX"
    Resolved WorksForMe -> "WORKSFORME"
    Resolved Incomplete -> "INCOMPLETE"
    Resolved (Duplicate id) -> "DUPLICATE"
    Resolved UnknownResolution -> "(unknown)"
    Verified Fixed -> "FIXED"
    Verified Invalid -> "INVALID"
    Verified WontFix -> "WONTFIX"
    Verified WorksForMe -> "WORKSFORME"
    Verified Incomplete -> "INCOMPLETE"
    Verified (Duplicate id) -> "DUPLICATE"
    Verified UnknownResolution -> "(unknown)"
    UnknownStatus -> "(unknown)"

bugOpen : Bug -> Bool
bugOpen bug =
  case bug.status of
    Resolved _ -> False
    _ -> True

urlForId : Int -> String
urlForId id =
  "https://bugzilla.mozilla.org/show_bug.cgi?id=" ++ (toString id)


-- HTTP

fetch : Cmd Msg
fetch =
  let
    url =
      -- https://bugzilla.mozilla.org/rest/bug?keywords=DevAdvocacy&include_fields=id,summary,status,resolution,is_open,dupe_of,product,component,creator,creation_time,whiteboard
      "http://localhost:3000/db"
  in
    Task.perform FetchFail FetchOk (Http.get decodeBugs url)

decodeBugs : Decoder (List Bug)
decodeBugs =
  at ["bugs"] (Json.Decode.list decodeBug)

decodeBug : Decoder Bug
decodeBug =
  Pipeline.decode Bug
    |> Pipeline.required "id" int
    |> Pipeline.required "summary" string
    |> Pipeline.custom statusDecoder
    |> Pipeline.custom priorityDecoder
    |> Pipeline.required "product" string
    |> Pipeline.required "component" string
    -- Other fields of interest:
    -- open, created, creator


statusDecoder : Decoder Status
statusDecoder =
  object3 (,,)
    ("status" := string)
    ("resolution" := string)
    (maybe ("dupe_of" := int))
  `andThen`
  statusInfo

statusInfo : (String, String, Maybe Int) -> Decoder Status
statusInfo (status, resolution, dupe) =
  let result =
    case status of
      "NEW" -> New
      "UNCONFIRMED" -> Unconfirmed
      "ASSIGNED" -> Assigned
      "RESOLVED" -> case resolution of
        "FIXED" -> Resolved Fixed
        "INVALID" -> Resolved Invalid
        "WONTFIX" -> Resolved WontFix
        "DUPLICATE" -> case dupe of
          Just id -> Resolved (Duplicate id)
          Nothing -> Resolved UnknownResolution
        "WORKSFORME" -> Resolved WorksForMe
        "INCOMPLETE" -> Resolved Incomplete
        _ -> Resolved UnknownResolution
      "VERIFIED" -> case resolution of
        "FIXED" -> Verified Fixed
        "INVALID" -> Verified Invalid
        "WONTFIX" -> Verified WontFix
        "DUPLICATE" -> case dupe of
          Just id -> Verified (Duplicate id)
          Nothing -> Verified UnknownResolution
        "WORKSFORME" -> Verified WorksForMe
        "INCOMPLETE" -> Verified Incomplete
        _ -> Verified UnknownResolution
      "REOPENED" -> Reopened
      _ -> UnknownStatus
  in
    succeed result

priorityDecoder : Decoder Priority
priorityDecoder =
  ("whiteboard" := string) `andThen` prioFromWhiteboard

prioFromWhiteboard : String -> Decoder Priority
prioFromWhiteboard wb =
  let
    wb' =
      toLower wb
    re =
      Regex.regex "\\[devrel:p(.)\\]"
    matches =
      Regex.find (Regex.AtMost 1) re wb'
    p =
      case matches of
        [] -> 
          Untriaged
        x :: _ ->
          case x.submatches of
            [] ->
              Untriaged
            y :: _ ->
              case y of 
                Just "1" -> P1
                Just "2" -> P2
                Just "3" -> P3
                Just "x" -> PX
                _ -> Untriaged
  in
    succeed p

module Bugzilla exposing (Model, Msg, update, view, init)

import Html exposing (Html, a, div, em, h1, li, strong, text, ul)
import Html.Attributes exposing (attribute, class, href, target, title)
import Http
import Json.Decode exposing ((:=), Decoder, andThen, at, int, list, maybe, object3, string, succeed)
import Json.Decode.Pipeline exposing (custom, decode, required)
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
  div
    [ class "bug"
    , attribute "data-open" (toString <| bugOpen bug)
    , attribute "data-status" (bugStatus bug)
    ]
    [ div
        [ class "bug-header" ]
        [ bugLink [ class "bug-id" ] bug ("#" ++ (toString bug.id))
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
  at ["bugs"] (list decodeBug)

decodeBug : Decoder Bug
decodeBug =
  decode Bug
    |> required "id" int
    |> required "summary" string
    |> custom statusDecoder
    -- Other fields of interest:
    -- open, created, creator, whiteboard, product, component


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

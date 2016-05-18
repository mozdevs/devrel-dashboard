module Bugzilla exposing (..)

import Http
import Json.Decode exposing ((:=), Decoder, andThen, at, int, list, maybe, object3, string, succeed)
import Json.Decode.Pipeline exposing (custom, decode, required)
import Task


-- MODEL

type alias Model =
  List Bug

type alias Bug =
  { id : Int
  , summary : String
  , status : Status
  }

type Status
  = Unconfirmed
  | New
  | Assigned
  | Resolved Resolution
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
        "WORKSFORME" -> Resolved WorksForMe
        "INCOMPLETE" -> Resolved Incomplete
        "DUPLICATE" -> case dupe of
          Just id -> Resolved (Duplicate id)
          Nothing -> Resolved UnknownResolution
        _ -> Resolved UnknownResolution
      _ -> UnknownStatus
  in
    succeed result

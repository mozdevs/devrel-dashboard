module Bugzilla.Commands exposing (fetch)

import Bugzilla.Messages exposing (Msg(FetchFail, FetchOk))
import Bugzilla.Models exposing (Bug, Priority(..), Resolution(..), State(..))
import Dict exposing (Dict)
import Http
import Json.Decode exposing ((:=), Decoder, at, andThen, int, list, maybe, object3, string)
import Json.Decode.Extra exposing ((|:), dict2)
import Regex
import String
import Task exposing (Task)


-- COMMANDS


fetch : Cmd Msg
fetch =
    let
        url : String
        url =
            Http.url "https://bugzilla.mozilla.org/rest/bug"
                [ ( "keywords", "DevAdvocacy" )
                , ( "include_fields"
                  , String.join ","
                        [ "id"
                        , "summary"
                        , "status"
                        , "resolution"
                        , "dupe_of"
                        , "product"
                        , "component"
                        , "whiteboard"
                        ]
                  )
                ]
    in
        Task.perform FetchFail FetchOk
            <| getJson bzDecoder url



-- HELPERS


getJson : Decoder a -> String -> Task Http.Error a
getJson decoder url =
    Http.send Http.defaultSettings
        { verb = "GET"
        , headers = [ ( "Accept", "application/json" ) ]
        , url = url
        , body = Http.empty
        }
        |> Http.fromJson decoder



-- JSON


bzDecoder : Decoder (Dict Int Bug)
bzDecoder =
    let
        asTuple : Bug -> ( Int, Bug )
        asTuple bug =
            ( bug.id, bug )

        toDict : List Bug -> Dict Int Bug
        toDict bugs =
            bugs |> List.map asTuple |> Dict.fromList
    in
        at [ "bugs" ] (list bugDecoder)
            |> Json.Decode.map toDict


bugDecoder : Decoder Bug
bugDecoder =
    Json.Decode.succeed Bug
        |: ("id" := int)
        |: ("summary" := string)
        |: ("product" := string)
        |: ("component" := string)
        |: andThen
            -- "state"
            (object3 (,,)
                ("status" := string)
                ("resolution" := string)
                ("dupe_of" := maybe int)
            )
            decodeState
        |: andThen
            -- "priority"
            ("whiteboard" := string)
            decodePriority
        |: andThen
            -- "open"
            ("status" := string)
            decodeOpen


decodeState : ( String, String, Maybe Int ) -> Decoder (Maybe State)
decodeState ( status, resolution, dupeOf ) =
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
                    Maybe.map Resolved resolution'

                "VERIFIED" ->
                    Maybe.map Verified resolution'

                _ ->
                    Nothing
    in
        Json.Decode.succeed state


decodePriority : String -> Decoder (Maybe Priority)
decodePriority whiteboard =
    let
        pattern =
            Regex.regex "\\[devrel:p(.)\\]"

        matches =
            Regex.find (Regex.AtMost 1) pattern (String.toLower whiteboard)

        submatches =
            List.map .submatches matches

        priority =
            case submatches of
                [ (Just "1") :: _ ] ->
                    Just P1

                [ (Just "2") :: _ ] ->
                    Just P2

                [ (Just "3") :: _ ] ->
                    Just P3

                [ (Just "x") :: _ ] ->
                    Just PX

                _ ->
                    Nothing
    in
        Json.Decode.succeed priority


decodeOpen : String -> Decoder Bool
decodeOpen status =
    Json.Decode.succeed (not (status == "RESOLVED" || status == "VERIFIED"))

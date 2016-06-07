module Bugzilla.Commands exposing (..)

import Bugzilla.Messages exposing (Msg(..))
import Bugzilla.Models exposing (Bug, Priority(..), State(..), Resolution(..))
import Dict exposing (Dict)
import Http
import Json.Decode exposing ((:=), Decoder, at, andThen, int, list, string, maybe, object3, succeed)
import Json.Decode.Extra exposing ((|:), dict2)
import Regex
import String
import Task


-- HTTP


fetch : Cmd Msg
fetch =
    let
        url =
            Http.url
                -- "http://localhost:3000/db"
                "https://bugzilla.mozilla.org/rest/bug"
                [ ( "keywords", "DevAdvocacy" )
                , (,) "include_fields"
                    (String.join ","
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
            <| Http.fromJson bugDecoder
            <| Http.send Http.defaultSettings
                { verb = "GET"
                , headers = [ ( "Accept", "application/json" ) ]
                , url = url
                , body = Http.empty
                }



-- JSON


bugDecoder : Decoder (Dict Int Bug)
bugDecoder =
    let
        asTuple : Bug -> ( Int, Bug )
        asTuple bug =
            ( bug.id, bug )

        toDict : List Bug -> Dict Int Bug
        toDict bugs =
            Dict.fromList << List.map asTuple <| bugs
    in
        at [ "bugs" ] (list decBug)
            |> Json.Decode.map toDict


decBug : Decoder Bug
decBug =
    succeed Bug
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
            decState
        |: andThen
            -- "priority"
            ("whiteboard" := string)
            decPrio
        |: andThen
            -- "open"
            ("status" := string)
            decOpen


decState : ( String, String, Maybe Int ) -> Decoder (Maybe State)
decState ( status, resolution, dupeOf ) =
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
        succeed state


decPrio : String -> Decoder (Maybe Priority)
decPrio whiteboard =
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
        succeed priority


decOpen : String -> Decoder Bool
decOpen status =
    succeed (status /= "RESOLVED" && status /= "VERIFIED")

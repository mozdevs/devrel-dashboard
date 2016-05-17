module Main exposing (..)

import Html exposing (Html, text, h1)
import Html.App
import Http
import Json.Decode
import Task


-- MODEL

type alias Model =
  { count : Int
  }


-- UPDATE

type Msg
  = FetchOk Int
  | FetchFail Http.Error

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchFail _ ->
      (model, Cmd.none)
    FetchOk count ->
      ({ model | count = count }, Cmd.none )


-- VIEW

view : Model -> Html Msg
view model =
  h1 [] [ text (toString model.count) ]


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- INIT

init : (Model, Cmd Msg)
init =
  (Model 0, fetchBugs)

main =
  Html.App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- Scratch

fetchBugs : Cmd Msg
fetchBugs =
  let
    url =
      "http://localhost:3000/db"
  in
    Task.perform FetchFail FetchOk (Http.get decodeCount url)

decodeCount : Json.Decode.Decoder Int
decodeCount =
  Json.Decode.succeed -1


{-
Full Bugzilla URL:
https://bugzilla.mozilla.org/rest/bug?keywords=DevAdvocacy&include_fields=id,summary,status,resolution,is_open,dupe_of,product,component,creator,creation_time,whiteboard
Using json-server:
localhost:3000/db
-}

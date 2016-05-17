module Main exposing (..)

import Html exposing (Html, text, h1)
import Html.App


-- MODEL

type alias Model =
  {
  }


-- UPDATE

type Msg
  = NoOp

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)


-- VIEW

view : Model -> Html Msg
view model =
  h1 [] [ text "Hello, world" ]


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- INIT

init : (Model, Cmd Msg)
init =
  ({}, Cmd.none)

main =
  Html.App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

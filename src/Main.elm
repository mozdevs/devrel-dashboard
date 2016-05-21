module Main exposing (..)

import Bugzilla
import Html exposing (Html, div)
import Html.App


-- MODEL

type alias Model =
  { bugs : Bugzilla.Model
  }


-- UPDATE

type Msg
  = Bugs Bugzilla.Msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Bugs subMsg ->
      let
        (model', cmd) =
          Bugzilla.update subMsg model.bugs
      in
        ({ model | bugs = model' }, Cmd.map Bugs cmd)


-- VIEW

view : Model -> Html Msg
view model =
  Html.App.map Bugs (Bugzilla.view model.bugs)


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- INIT

init : (Model, Cmd Msg)
init =
  let
    (bugs, bugsCmd) =
      Bugzilla.init
  in
    ( Model bugs
    , Cmd.map Bugs bugsCmd
    )

main : Program Never
main =
  Html.App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

module Main exposing (..)

import Bugzilla exposing (Bug)
import Html exposing (Html, h1, li, text, ul)
import Html.App


-- MODEL

type alias Model =
  { bugs : Bugzilla.Model
  }


-- UPDATE

type Msg
  = BzMsg Bugzilla.Msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    BzMsg subMsg ->
      let
        (model', cmd) =
          Bugzilla.update subMsg model.bugs
      in
        ({ model | bugs = model' }, Cmd.map BzMsg cmd)


-- VIEW

view : Model -> Html Msg
view model =
  ul
    []
    (List.map viewBug model.bugs)

viewBug : Bug -> Html Msg
viewBug bug =
  li
    []
    [ text (toString bug.id ++ "—" ++ bug.summary) ]


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- INIT

init : (Model, Cmd Msg)
init =
  ({ bugs = [] }, Cmd.map BzMsg Bugzilla.fetch)

main : Program Never
main =
  Html.App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

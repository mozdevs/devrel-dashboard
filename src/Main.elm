module Main exposing (..)

import Bugzilla.Commands
import Bugzilla.Models
import Bugzilla.Messages
import Bugzilla.View
import Bugzilla.Update
import Html exposing (Html, div, text, h1)
import Html.Attributes exposing (id)
import Html.App


-- MODEL


type alias Model =
    { bugs : Bugzilla.Models.Model
    }


-- UPDATE


type Msg
    = BugzillaMsg Bugzilla.Messages.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BugzillaMsg subMsg ->
            let
                ( model', cmd ) =
                    Bugzilla.Update.update subMsg model.bugs
            in
                ( { model | bugs = model' }, Cmd.map BugzillaMsg cmd )


-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [ id "header" ]
            [ h1 [] [ text "Mozilla DevRel Dashboard" ] ]
        , div [ id "content" ]
            [ Html.App.map BugzillaMsg (Bugzilla.View.view model.bugs) ]
        ]


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


-- INIT


init : ( Model, Cmd Msg )
init =
    let
        ( bugs, bugsCmd ) =
            (Bugzilla.Models.initialModel, Bugzilla.Commands.fetch)
    in
        ( Model bugs
        , Cmd.map BugzillaMsg bugsCmd
        )


main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

module Bugzilla.Update exposing (..)

import Bugzilla.Models exposing (Model, SortDir(..), Network(..))
import Bugzilla.Messages exposing (Msg(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchFail _ ->
            ( { model | networkStatus = Failed }, Cmd.none )

        FetchOk bugs ->
            ( { model | bugs = bugs, networkStatus = Loaded }, Cmd.none )

        SortBy field ->
            let
                ( curField, curDir ) =
                    model.sort

                toggle direction =
                    case direction of
                        Asc ->
                            Desc

                        Desc ->
                            Asc
            in
                if field == curField then
                    ( { model | sort = ( field, toggle curDir ) }, Cmd.none )
                else
                    ( { model | sort = ( field, Asc ) }, Cmd.none )

        ToggleShowClosed ->
            ( { model | showClosed = not model.showClosed }, Cmd.none )

        TogglePriority priority ->
            let
                newPriorities =
                    if List.member priority model.showPriorities then
                        List.filter ((/=) priority) model.showPriorities
                    else
                        priority :: model.showPriorities
            in
                ( { model | showPriorities = newPriorities }, Cmd.none )

        FilterText s ->
            ( { model | filterText = s }, Cmd.none )

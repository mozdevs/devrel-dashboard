module Bugzilla.Update exposing (update)

import Bugzilla.Models exposing (Model, SortDir(Asc, Desc), Network(Failed, Loaded))
import Bugzilla.Messages exposing (Msg(..))
import Set


update : Msg -> Model -> Model
update msg model =
    case msg of
        FetchFail _ ->
            { model | networkStatus = Failed }

        FetchOk bugs ->
            { model | bugs = bugs, networkStatus = Loaded }

        SortBy newField ->
            let
                ( curField, curDir ) =
                    model.sort

                newDir =
                    if newField == curField then
                        inverse curDir
                    else
                        Asc
            in
                { model | sort = ( newField, newDir ) }

        ToggleShowClosed ->
            { model | showClosed = not model.showClosed }

        TogglePriority priority ->
            let
                newPriorities =
                    if List.member priority model.visiblePriorities then
                        List.filter ((/=) priority) model.visiblePriorities
                    else
                        priority :: model.visiblePriorities
            in
                { model | visiblePriorities = newPriorities }

        FilterText s ->
            { model | filterText = s }



-- HELPERS


inverse : SortDir -> SortDir
inverse direction =
    case direction of
        Asc ->
            Desc

        Desc ->
            Asc

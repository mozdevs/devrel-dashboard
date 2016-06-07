module Bugzilla.View exposing (..)

import Bugzilla.Models exposing (Model, Bug, Priority(..), Resolution(..), SortDir(..), SortField(..), State(..), Network(..))
import Bugzilla.Messages exposing (Msg(..))
import Dict
import Html exposing (..)
import Html.Attributes exposing (id, class, attribute, target, href, title, classList, type', checked, value, placeholder)
import Html.Events exposing (onClick, onCheck, onInput)
import Set
import String

view : Model -> Html Msg
view model =
    let
        sortWidget : ( SortField, String ) -> Html Msg
        sortWidget ( field, label ) =
            button
                [ onClick <| SortBy field
                , classList
                    [ ( "as-text", True )
                    , ( "active", field == fst model.sort )
                    , ( "sort-asc", model.sort == ( field, Asc ) )
                    , ( "sort-desc", model.sort == ( field, Desc ) )
                    ]
                ]
                [ text label ]

        closedWidget =
            label []
                [ input
                    [ type' "checkbox"
                    , checked <| not model.showClosed
                    , onCheck <| always ToggleShowClosed
                    ]
                    []
                , text "Hide Closed Bugs"
                ]

        prioWidget ( priority, labelText, meaning ) =
            let
                prioString =
                    Maybe.withDefault "Untriaged" (Maybe.map toString priority)
            in
                label
                    [ class "priority-widget"
                    , title <| labelText ++ "—" ++ meaning
                    ]
                    [ input
                        [ type' "checkbox"
                        , checked (List.member priority model.showPriorities)
                        , onCheck <| always (TogglePriority priority)
                        ]
                        []
                    , if meaning /= "" then
                        abbr
                            [ class <| String.toLower ("priority-filter-" ++ prioString)
                            , title <| labelText ++ "—" ++ meaning
                            ]
                            [ text labelText ]
                      else
                        span [ class <| String.toLower ("priority-filter-" ++ prioString) ]
                            [ text labelText ]
                    ]

        sortBar =
            div [ id "sort-bar" ]
                [ input
                    [ class "filter-text"
                    , attribute "list" "datalist-products"
                    , placeholder "Filter Bugs by Product, Component, or Summary Text"
                    , onInput FilterText
                    ]
                    []
                , datalist [ id "datalist-products" ]
                    (model.bugs
                        |> Dict.values
                        |> List.map (\bug -> [ bug.product, bug.product ++ " :: " ++ bug.component ])
                        |> List.concat
                        |> Set.fromList
                        |> Set.toList
                        |> List.map (\product -> option [ value product ] [])
                    )
                , div [ class "filter-priorities" ]
                    ([ ( Just P1, "P1", "Critical" )
                     , ( Just P2, "P2", "Major" )
                     , ( Just P3, "P3", "Minor" )
                     , ( Just PX, "PX", "Ignore" )
                     , ( Nothing, "Untriaged", "" )
                     ]
                        |> List.map prioWidget
                        |> List.intersperse (text ", ")
                        |> (::) (text "Priorities: ")
                    )
                , closedWidget
                , div []
                    ([ ( Id, "Number" )
                     , ( ProductComponent, "Product / Component" )
                     , ( Priority, "Priority" )
                     ]
                        |> List.map sortWidget
                        |> List.intersperse (text ", ")
                        |> (::) (text "Sort: ")
                    )
                ]

        matchesFilterText bug =
            List.any (String.contains <| String.toLower model.filterText)
                [ String.toLower (bug.product ++ " :: " ++ bug.component)
                , String.toLower bug.summary
                ]

        matchesPriority bug =
            List.isEmpty model.showPriorities || List.member bug.priority model.showPriorities

        matchesShowOpen bug =
            bug.open || model.showClosed
    in
        div [ class "bugs" ]
            [ sortBar
            , case model.networkStatus of
                Fetching ->
                    div [ class "loading" ] [ text "Fetching data from Bugzilla..." ]

                Failed ->
                    div [ class "loading-error" ] [ text "Error fetching data. Please refresh." ]

                Loaded ->
                    let
                        bugs =
                            List.map (\bug -> li [] [ viewBug bug ])
                                <| sortBugs model.sort
                                <| List.filter matchesFilterText
                                <| List.filter matchesPriority
                                <| List.filter matchesShowOpen
                                <| Dict.values model.bugs
                    in
                        if List.isEmpty bugs then
                            div [ class "no-bugs" ] [ text "No bugs match your filter settings." ]
                        else
                            ul [] bugs
            ]


sortBugs : ( SortField, SortDir ) -> List Bug -> List Bug
sortBugs ( field, direction ) bugs =
    let
        statusOrd state =
            case state of
                Nothing ->
                    0

                Just Unconfirmed ->
                    1

                Just New ->
                    1

                Just Reopened ->
                    1

                Just Assigned ->
                    2

                Just (Resolved (Duplicate _)) ->
                    3

                Just (Verified (Duplicate _)) ->
                    3

                Just (Resolved Fixed) ->
                    4

                Just (Verified Fixed) ->
                    4

                Just (Resolved Incomplete) ->
                    5

                Just (Verified Incomplete) ->
                    5

                Just (Resolved Invalid) ->
                    6

                Just (Verified Invalid) ->
                    6

                Just (Resolved WontFix) ->
                    7

                Just (Verified WontFix) ->
                    7

                Just (Resolved WorksForMe) ->
                    8

                Just (Verified WorksForMe) ->
                    8

        prioOrd priority =
            case priority of
                Just P1 ->
                    1

                Just P2 ->
                    2

                Just P3 ->
                    3

                Just PX ->
                    4

                Nothing ->
                    5

        fn =
            case field of
                Id ->
                    List.sortBy .id

                ProductComponent ->
                    List.sortBy (\x -> ( x.product, x.component, x.summary ))

                Priority ->
                    List.sortBy (\x -> ( prioOrd x.priority, x.product, x.component, x.summary ))
    in
        fn bugs
            |> if direction == Desc then
                List.reverse
               else
                identity


viewBug : Bug -> Html Msg
viewBug bug =
    let
        bugUrl =
            "https://bugzilla.mozilla.org/show_bug.cgi?id=" ++ (toString bug.id)

        stateString =
            case bug.state of
                Just (Resolved (Duplicate _)) ->
                    "Duplicate"

                Just (Verified (Duplicate _)) ->
                    "Duplicate"

                Just (Resolved resolution) ->
                    toString resolution

                Just (Verified resolution) ->
                    toString resolution

                Just Assigned ->
                    "Assigned"

                Just New ->
                    ""

                Just Unconfirmed ->
                    ""

                Just Reopened ->
                    ""

                Nothing ->
                    "(Unknown Status)"

        prioString =
            Maybe.withDefault "Untriaged" (Maybe.map toString bug.priority)

        pcString =
            bug.product ++ " :: " ++ bug.component
    in
        div
            [ class "bug"
            , attribute "data-open" (toString bug.open)
            , attribute "data-status" stateString
            , attribute "data-priority" prioString
            ]
            [ div [ class "bug-header" ]
                [ div [ class "oneline", title pcString ]
                    [ text pcString ]
                ]
            , div [ class "bug-body" ]
                [ a [ target "_blank", href bugUrl, class "bug-summary" ]
                    [ text bug.summary ]
                , a [ target "_blank", href bugUrl, class "bug-id" ]
                    [ text <| "#" ++ (toString bug.id) ]
                ]
            ]

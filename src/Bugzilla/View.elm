module Bugzilla.View exposing (..)

import Bugzilla.Models exposing (Model, Bug, Priority(..), Resolution(..), SortDir(..), SortField(..), State(..), Network(..))
import Bugzilla.Messages exposing (Msg(..))
import Bugzilla.ViewHelpers exposing (baseComponent, bugTaxon, stateDescription, stateOrder, priorityOrder)
import Dict exposing (Dict)
import Dict.Extra exposing (groupBy)
import Html exposing (..)
import Html.Attributes exposing (id, class, attribute, target, href, title, classList, type', checked, value, placeholder)
import Html.Events exposing (onClick, onCheck, onInput)
import Set
import String


-- VIEW


view : Model -> Html Msg
view model =
    let
        visibleBugs : List Bug
        visibleBugs =
            model.bugs
                |> Dict.values
                |> List.filter (matchesShowOpen model)
                |> List.filter (matchesPriority model)
                |> List.filter (matchesFilterText model)
                |> sortBugs model.sort
    in
        div [ class "bugs" ]
            [ sortContainer model
            , case model.networkStatus of
                Fetching ->
                    div [ class "loading" ] [ text "Fetching data from Bugzilla..." ]

                Failed ->
                    div [ class "loading-error" ] [ text "Error fetching data. Please refresh." ]

                Loaded ->
                    if List.isEmpty visibleBugs then
                        div [ class "no-bugs" ] [ text "No bugs match your current filters." ]
                    else if fst model.sort == ProductComponent then
                        visibleBugs
                            |> groupBugs2 .product baseComponent
                            |> renderNestedBugs
                    else
                        div [] (List.map renderStandaloneBug visibleBugs)
            ]



-- HELPERS : Predicates


matchesFilterText : Model -> Bug -> Bool
matchesFilterText model bug =
    List.any (String.contains <| String.toLower model.filterText)
        [ String.toLower (bugTaxon bug)
        , String.toLower bug.summary
        ]


matchesPriority : Model -> Bug -> Bool
matchesPriority { visiblePriorities } { priority } =
    List.isEmpty visiblePriorities || List.member priority visiblePriorities


matchesShowOpen : Model -> Bug -> Bool
matchesShowOpen { showClosed } { open } =
    open || showClosed



-- HELPERS : Transformations


sortBugs : ( SortField, SortDir ) -> List Bug -> List Bug
sortBugs ( field, direction ) bugs =
    let
        sort =
            case field of
                Id ->
                    List.sortBy .id

                ProductComponent ->
                    List.sortBy (\x -> ( x.product, baseComponent x, priorityOrder x.priority, x.summary ))

                Priority ->
                    List.sortBy (\x -> ( priorityOrder x.priority, x.product, x.component, x.summary ))

        transform =
            if direction == Desc || field == ProductComponent then
                List.reverse
            else
                identity
    in
        bugs
            |> sort
            |> transform



-- WIDGETS : Bugs


groupBugs : (Bug -> String) -> List Bug -> List ( String, List Bug )
groupBugs selector bugs =
    Dict.Extra.groupBy selector bugs
        |> Dict.toList


groupBugs2 :
    (Bug -> String)
    -> (Bug -> String)
    -> List Bug
    -> List ( String, List ( String, List Bug ) )
groupBugs2 groupSel subgroupSel bugs =
    groupBugs groupSel bugs
        |> List.map (\( group, bugs' ) -> ( group, groupBugs subgroupSel bugs' ))


renderNestedBugs : List ( String, List ( String, List Bug ) ) -> Html Msg
renderNestedBugs groups =
    div []
        (List.concatMap
            (\( group, subgroups ) ->
                h2 [] [ text group ]
                    :: List.concatMap
                        (\( subgroup, bugs ) ->
                            span [] [ text subgroup ]
                                :: (List.map renderMinimalBug
                                        <| List.sortBy
                                            (\x ->
                                                ( priorityOrder x.priority, x.summary )
                                            )
                                        <| bugs
                                   )
                        )
                        subgroups
            )
            groups
        )


renderStandaloneBug : Bug -> Html Msg
renderStandaloneBug bug =
    let
        bugUrl =
            "https://bugzilla.mozilla.org/show_bug.cgi?id=" ++ (toString bug.id)

        prioString =
            Maybe.withDefault "Untriaged" (Maybe.map toString bug.priority)
    in
        div
            [ class "bug"
            , attribute "data-open" (toString bug.open)
            , attribute "data-status" (stateDescription bug.state)
            , attribute "data-priority" prioString
            ]
            [ div [ class "bug-header" ]
                [ div [ class "oneline", title (bugTaxon bug) ]
                    [ text (bugTaxon bug) ]
                ]
            , div [ class "bug-body" ]
                [ a [ target "_blank", href bugUrl, class "bug-summary" ]
                    [ text bug.summary ]
                , a [ target "_blank", href bugUrl, class "bug-id" ]
                    [ text <| "#" ++ (toString bug.id) ]
                ]
            ]


renderMinimalBug : Bug -> Html Msg
renderMinimalBug bug =
    let
        bugUrl =
            "https://bugzilla.mozilla.org/show_bug.cgi?id=" ++ (toString bug.id)

        prioString =
            Maybe.withDefault "Untriaged" (Maybe.map toString bug.priority)
    in
        div
            [ class "bug"
            , attribute "data-open" (toString bug.open)
            , attribute "data-status" (stateDescription bug.state)
            , attribute "data-priority" prioString
            ]
            [ div [ class "bug-body" ]
                [ a [ target "_blank", href bugUrl, class "bug-summary" ]
                    [ text bug.summary ]
                , a [ target "_blank", href bugUrl, class "bug-id" ]
                    [ text <| "#" ++ (toString bug.id) ]
                ]
            ]



-- WIDGETS : Sorting and Filtering


sortContainer : Model -> Html Msg
sortContainer model =
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
                |> List.map (\bug -> [ bug.product, bugTaxon bug ])
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
                |> List.map (priorityFilterWidget model)
                |> List.intersperse (text ", ")
                |> (::) (text "Priorities: ")
            )
        , closedFilterWidget model
        , div []
            ([ ( Id, "Number" )
             , ( ProductComponent, "Product / Component" )
             , ( Priority, "Priority" )
             ]
                |> List.map (sortWidget model)
                |> List.intersperse (text ", ")
                |> (::) (text "Sort: ")
            )
        ]


sortWidget : Model -> ( SortField, String ) -> Html Msg
sortWidget model ( field, label ) =
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


closedFilterWidget : Model -> Html Msg
closedFilterWidget model =
    label []
        [ input
            [ type' "checkbox"
            , checked <| not model.showClosed
            , onCheck <| always ToggleShowClosed
            ]
            []
        , text "Hide Closed Bugs"
        ]


priorityFilterWidget : Model -> ( Maybe Priority, String, String ) -> Html Msg
priorityFilterWidget model ( priority, description, explanation ) =
    let
        tooltip : String
        tooltip =
            if explanation == "" then
                ""
            else
                description ++ "—" ++ explanation

        filterClass : String
        filterClass =
            priority
                |> Maybe.map toString
                |> Maybe.withDefault "untriaged"
                |> (++) "priority-filter-"
                |> String.toLower
    in
        label
            [ class "priority-widget"
            , title tooltip
            ]
            [ input
                [ type' "checkbox"
                , checked (List.member priority model.visiblePriorities)
                , onCheck <| always (TogglePriority priority)
                ]
                []
            , (if explanation == "" then
                span
               else
                abbr
              )
                [ class filterClass ]
                [ text description ]
            ]

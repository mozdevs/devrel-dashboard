module Bugzilla.ViewHelpers exposing (..)

import Bugzilla.Models exposing (Bug, Priority(..), Resolution(..), State(..))
import List
import Maybe
import String


baseComponent : Bug -> String
baseComponent =
    .component >> String.split ":" >> List.head >> Maybe.withDefault ""


bugTaxon : Bug -> String
bugTaxon bug =
    bug.product ++ " :: " ++ bug.component


stateDescription : Maybe State -> String
stateDescription state =
    case state of
        Just New -> ""
        Just Unconfirmed -> ""
        Just Reopened -> ""

        Just Assigned -> "Assigned"

        Just (Resolved (Duplicate _)) -> "Duplicate"
        Just (Verified (Duplicate _)) -> "Duplicate"

        Just (Resolved resolution) -> toString resolution
        Just (Verified resolution) -> toString resolution

        Nothing -> "(Unknown Status)"


stateOrder : Maybe State -> Int
stateOrder state =
    case state of
        Nothing -> 0

        Just Unconfirmed -> 1
        Just New -> 1
        Just Reopened -> 1

        Just Assigned -> 2

        Just (Resolved (Duplicate _)) -> 3
        Just (Verified (Duplicate _)) -> 3

        Just (Resolved Fixed) -> 4
        Just (Verified Fixed) -> 4

        Just (Resolved Incomplete) -> 5
        Just (Verified Incomplete) -> 5

        Just (Resolved Invalid) -> 6
        Just (Verified Invalid) -> 6

        Just (Resolved WontFix) -> 7
        Just (Verified WontFix) -> 7

        Just (Resolved WorksForMe) -> 8
        Just (Verified WorksForMe) -> 8


priorityOrder : Maybe Priority -> Int
priorityOrder priority =
    case priority of
        Just P1 -> 1
        Just P2 -> 2
        Just P3 -> 3
        Just PX -> 4
        Nothing -> 5

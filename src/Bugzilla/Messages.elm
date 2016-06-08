module Bugzilla.Messages exposing (Msg(..))

import Bugzilla.Models exposing (Bug, Priority, SortField)
import Dict exposing (Dict)
import Http


type Msg
    = FetchOk (Dict Int Bug)
    | FetchFail Http.Error
    | SortBy SortField
    | ToggleShowClosed
    | TogglePriority (Maybe Priority)
    | FilterText String

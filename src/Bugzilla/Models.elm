module Bugzilla.Models exposing (..)

import Dict exposing (Dict)


-- MODEL


type alias Model =
    { bugs : Dict Int Bug
    , sort : ( SortField, SortDir )
    , showClosed : Bool
    , visiblePriorities : List (Maybe Priority)
    , filterText : String
    , networkStatus : Network
    }


initialModel : Model
initialModel =
    { bugs = Dict.empty
    , sort = ( Priority, Asc )
    , showClosed = False
    , visiblePriorities = [ Just P1, Just P2, Just P3 ]
    , filterText = ""
    , networkStatus = Fetching
    }



-- TYPES


type alias Bug =
    { id : Int
    , summary : String
    , product : String
    , component : String
    , state : Maybe State
    , priority : Maybe Priority
    , open : Bool
    }


type State
    = Unconfirmed
    | New
    | Assigned
    | Reopened
    | Resolved Resolution
    | Verified Resolution


type Resolution
    = Fixed
    | Invalid
    | WontFix
    | Duplicate Int
    | WorksForMe
    | Incomplete


type Priority
    = P1
    | P2
    | P3
    | PX


type SortField
    = Id
    | ProductComponent
    | Priority


type SortDir
    = Asc
    | Desc


type Network
    = Fetching
    | Loaded
    | Failed

import Immutable from 'immutable';
import { combineReducers } from 'redux-immutable';

import {
  SELECT_PRODUCT, TOGGLE_CLOSED, SORT_COLUMN,
  EXPIRE_BUGS, REQUEST_BUGS, RECEIVE_BUGS,
} from '../actions';

const meta = (state = Immutable.fromJS({
  isFetching: false,
  showClosed: false,
  sortColumn: 'id',
  sortDirection: 'asc',
}), action) => {
  switch (action.type) {
    case SELECT_PRODUCT:
      if (action.product === '(all)') {
        return state.delete('product');
      } else {
        return state.set('product', action.product);
      }
    case TOGGLE_CLOSED:
      return state.set('showClosed', !state.get('showClosed'));
    case SORT_COLUMN:
        let curCol = state.get('sortColumn');
        if (curCol === action.column) {
          let curDir = state.get('sortDirection');
          return state.set('sortDirection', curDir === 'desc' ? 'asc' : 'desc');
        } else {
          return state.withMutations(state => {
            state.set('sortColumn', action.column);
            state.set('sortDirection', 'desc');
          });
        }
    case EXPIRE_BUGS:
      return state.set('lastUpdated', undefined);
    case REQUEST_BUGS:
      return state.set('isFetching', true);
    case RECEIVE_BUGS:
      return state.withMutations(state => {
        state.set('isFetching', false);
        state.set('lastUpdated', action.receivedAt);
      });
    default:
      return state;
  }
};

const bugs = (state = Immutable.fromJS({ }), action) => {
  switch(action.type) {
    case EXPIRE_BUGS:
      return state.clear();
    case RECEIVE_BUGS:
      return Immutable.fromJS(action.bugs);
    default:
      return state;
  }
};

export default combineReducers({ meta, bugs });

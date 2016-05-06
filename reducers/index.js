import Immutable from 'immutable';
import { combineReducers } from 'redux-immutable';

import {
  SELECT_PRODUCT, SELECT_PRIORITY, TOGGLE_CLOSED, SORT_COLUMN,
  EXPIRE_BUGS, REQUEST_BUGS, RECEIVE_BUGS,
} from '../actions';

const meta = (state = Immutable.fromJS({
  isFetching: false,
  showClosed: false,
  sortColumn: 'product',
  sortDirection: 'asc',
  products: Immutable.Set(['(all)']),
  priorities: Immutable.Set(['1'])
}), action) => {
  switch (action.type) {
    case SELECT_PRODUCT:
      if (action.product === '(all)') {
        return state.updateIn(['products'], s => s.clear().add('(all)'));
      } else {
        return state.updateIn(['products'], s => {
          let method = s.includes(action.product) ? 'delete' : 'add';
          let result = s[method](action.product).delete('(all)');

          return result.isEmpty() ? result.add('(all)') : result;
        });
      }
    case SELECT_PRIORITY:
      if (action.priority === '(all)') {
        return state.updateIn(['priorities'], s => s.clear().add('(all)'));
      } else {
        return state.updateIn(['priorities'], s => {
          let method = s.includes(action.priority) ? 'delete' : 'add';
          let result = s[method](action.priority).delete('(all)');

          return result.isEmpty() ? result.add('(all)') : result;
        });
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
            state.set('sortDirection', 'asc');
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

import Immutable from 'immutable';

const initialState = Immutable.fromJS({
  showClosed: false,
  sort: {
    column: 'id',
    direction: 'asc',
  },
  network: {
    status: 'INIT',
  },
  data: {
    bugs: [],
  },
});

const reducer = (state = initialState, action) => {
  switch (action.type) {
    case 'TOGGLE_SHOW_CLOSED':
      return state.set('showClosed', !state.get('showClosed'));

    case 'TOGGLE_SORT_COLUMN':
      let curCol = state.getIn(['sort', 'column']);
      let curDir = state.getIn(['sort', 'direction']);
      if (action.column == curCol) {
        return state.setIn(['sort', 'direction'], curDir === 'desc' ? 'asc' : 'desc');
      } else {
        return state.set('sort', Immutable.Map({ column: action.column, direction: 'desc' }));
      }

    case 'UPDATE_NETWORK_STATUS':
      return state.setIn(['network', 'status'], action.status);

    case 'REPLACE_BUG_DATA':
      return state.setIn(['data', 'bugs'], Immutable.fromJS(action.data.bugs));

    default:
      return state;
  }
};

export default reducer;

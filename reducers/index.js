import Immutable from 'immutable';

const initialState = Immutable.fromJS({
  showClosed: false,
  sort: {
    column: 'id',
    direction: 'asc',
  }
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

    default:
      return state;
  }
};

export default reducer;

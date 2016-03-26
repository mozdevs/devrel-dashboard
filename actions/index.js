import fetch from 'isomorphic-fetch';

// Action Types

export const SELECT_PRODUCT = 'SELECT_PRODUCT';

export const TOGGLE_CLOSED = 'TOGGLE_CLOSED';

export const SORT_COLUMN = 'SORT_COLUMN';

export const EXPIRE_BUGS = 'EXPIRE_BUGS';
export const REQUEST_BUGS = 'REQUEST_BUGS';
export const RECEIVE_BUGS = 'RECEIVE_BUGS';

// Synchronous Actions

export const selectProduct = (product) => ({ type: SELECT_PRODUCT, product });

export const toggleClosed = () => ({ type: TOGGLE_CLOSED });

export const sortColumn = (column) => ({ type: SORT_COLUMN, column });

export const expireBugs = () => ({ type: EXPIRE_BUGS });
export const requestBugs = () => ({ type: REQUEST_BUGS });
export const receiveBugs = (json) => {
  let bugs = json.bugs.reduce((acc, item) => (acc[item.id] = item, acc), {});

  return {
    type: RECEIVE_BUGS,
    bugs,
    receivedAt: Date.now(),
  }
};


// Asynchronous Actions

export const fetchBugs = () => {
  return (dispatch) => {
    let bz_base = 'https://bugzilla.mozilla.org/rest/bug';
    let bz_fields = ['id', 'summary', 'status', 'resolution', 'is_open', 'dupe_of',
                     'product', 'component', 'creator', 'creation_time'];

    dispatch(requestBugs());
    return fetch(bz_base + '?keywords=DevAdvocacy&include_fields=' + bz_fields.join(','))
           .then(response => response.json())
           .then(json => dispatch(receiveBugs(json)));
  }
};

export const fetchBugsIfNeeded = () => {
  return (dispatch, getState) => {
    if (shouldFetchBugs(getState())) {
      return dispatch(fetchBugs());
    } else {
      return Promise.resolve();
    }
  }
}

// Utilities

const shouldFetchBugs = (state) => {
  let isFetching = state.getIn(['meta', 'isFetching']);
  let lastUpdated = state.getIn(['meta', 'lastUpdated']);
  let day = 24 * 60 * 60 * 1000;
  let dataIsFresh = lastUpdated && (Date.now() - lastUpdated < day);

  return !(isFetching || dataIsFresh);
}

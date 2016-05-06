import fetch from 'isomorphic-fetch';
import localforage from 'localforage';

const CACHE_VERSION = 1;

// Action Types

export const SELECT_PRODUCT = 'SELECT_PRODUCT';

export const SELECT_PRIORITY = 'SELECT_PRIORITY';

export const TOGGLE_CLOSED = 'TOGGLE_CLOSED';

export const SORT_COLUMN = 'SORT_COLUMN';

export const EXPIRE_BUGS = 'EXPIRE_BUGS';
export const REQUEST_BUGS = 'REQUEST_BUGS';
export const RECEIVE_BUGS = 'RECEIVE_BUGS';

// Synchronous Actions

export const selectProduct = (product) => ({ type: SELECT_PRODUCT, product });

export const selectPriority = (priority) => ({ type: SELECT_PRIORITY, priority });

export const toggleClosed = () => ({ type: TOGGLE_CLOSED });

export const sortColumn = (column) => ({ type: SORT_COLUMN, column });

export const expireBugs = () => ({ type: EXPIRE_BUGS });
export const requestBugs = () => ({ type: REQUEST_BUGS });
export const receiveBugs = (json, when = Date.now()) => {
  let bugs = json.bugs.reduce((acc, item) => (acc[item.id] = item, acc), {});

  return {
    type: RECEIVE_BUGS,
    bugs,
    receivedAt: when,
  }
};

// Asynchronous Actions

export const fetchBugs = () => {
  return (dispatch) => {
    let bz_base = 'https://bugzilla.mozilla.org/rest/bug';
    let bz_fields = [
      'id', 'summary', 'status', 'resolution', 'is_open', 'dupe_of',
      'product', 'component', 'creator', 'creation_time', 'whiteboard',
    ];

    let query = bz_base + '?keywords=DevAdvocacy&include_fields=' + bz_fields.join(',');

    dispatch(requestBugs());
    return fetch(query)
           .then(response => response.json())
           .then(json => {
             let when = Date.now();

             dispatch(receiveBugs(json, when));

             return updateCache(json, when);
           });
  }
};

export const fetchBugsIfNeeded = () => {
  return (dispatch, getState) => (
    loadFromCache()
    .then(
      ([json, when]) => dispatch(receiveBugs(json, when)),
      (e) => { /* Silently ignore cache loading errors */ }
    )
    .then(() => shouldFetchBugs(getState()) ? dispatch(fetchBugs()) : undefined)
  );
};

// Utilities

const shouldFetchBugs = (state) => {
  let isFetching = state.getIn(['meta', 'isFetching']);
  let lastUpdated = state.getIn(['meta', 'lastUpdated']);
  let day = 24 * 60 * 60 * 1000;
  let dataIsFresh = lastUpdated && (Date.now() - lastUpdated < day);

  return !(isFetching || dataIsFresh);
};

const loadFromCache = () => {
  return Promise.all([
    localforage.getItem('json'),
    localforage.getItem('when'),
    localforage.getItem('version')
  ])
  .then(([json, when, version]) => {
    if (version !== CACHE_VERSION) {
      throw new Error("Cache version mismatch; not using cached data.");
    } else {
      return [json, when];
    }
  })
};

const updateCache = (json, when) => {
  return Promise.all([
    localforage.setItem('json', json),
    localforage.setItem('when', when),
    localforage.setItem('version', CACHE_VERSION)
  ])
  .catch(e => localforage.clear())
  .catch(e => { /* Silently ignore further cache errors */ });
};

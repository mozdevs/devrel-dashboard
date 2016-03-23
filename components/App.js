import React from 'react';
import fetch from 'isomorphic-fetch';
import localforage from 'localforage';

import FilterBar from './FilterBar';
import BugList from './BugList';

const App = React.createClass({
  getInitialState: function() {
    return {
      bugs: [],
    }
  },

  componentDidMount: function() {
    let bz_api = 'https://bugzilla.mozilla.org/rest';
    let bz_fields = ['id', 'summary', 'status', 'resolution', 'is_open',
                     'dupe_of', 'keywords', 'whiteboard', 'product',
                     'component', 'creator', 'creator_detail', 'creation_time',
                     'last_change_time'];
    let bz_url = bz_api + '/bug?keywords=DevAdvocacy&include_fields=' + bz_fields.join(',');

    let setState = (newState) => this.setState(Object.assign({}, this.state, { bugs: newState.bugs }));

    function fetchAndStore(url) {
      return fetch(url)
             .then(response => response.json())
             .then(json => Promise.all([
               localforage.setItem('data', json),
               localforage.setItem('time', Date.now())
             ]))
             .then(([data, time]) => data)
    }

    Promise.all([localforage.getItem('data'), localforage.getItem('time')])
    .then(([data, time]) => {
      let age = Date.now() - time;
      let day = 24 * 60 * 60 * 1000;

      if (!data) {
        console.info("No cached data, fetching...");
        return fetchAndStore(bz_url);
      } else if (age >= day) {
        console.info("Displaying stale cached data, fetching fresh data...");
        setState(data);
        return fetchAndStore(bz_url);
      } else {
        console.info("Displaying fresh cached data, not fetching.");
        return data;
      }
    })
    .then(data => setState(data))
  },

  render: function() {
    return (
      <div>
        <FilterBar />
        <BugList bugs={this.state.bugs} />
      </div>
    );
  }
});

export default App;

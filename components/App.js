import React from 'react';
import { connect } from 'react-redux';
import fetch from 'isomorphic-fetch';
import localforage from 'localforage';

import PageHeader from './PageHeader';
import BugList from './BugList';

class App extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidMount() {
    let bz_api = 'https://bugzilla.mozilla.org/rest';
    let bz_fields = ['id', 'summary', 'status', 'resolution', 'is_open',
                     'dupe_of', 'keywords', 'whiteboard', 'product',
                     'component', 'creator', 'creator_detail', 'creation_time',
                     'last_change_time'];
    let bz_url = bz_api + '/bug?keywords=DevAdvocacy&include_fields=' + bz_fields.join(',');

    const fetchAndStore = (url) => {
      this.props.dispatch({ type: 'UPDATE_NETWORK_STATUS', status: 'LOAD_NETWORK' });
      return fetch(url)
             .then(response => response.json())
             .then(json => Promise.all([
               localforage.setItem('data', json),
               localforage.setItem('time', Date.now())
             ]))
             .then(([data, time]) => data)
    };

    Promise.resolve()
    .then(() => this.props.dispatch({ type: 'UPDATE_NETWORK_STATUS', status: 'LOAD_CACHE' }))
    .then(() => Promise.all([localforage.getItem('data'), localforage.getItem('time')]))
    .then(([data, time]) => {
      let age = Date.now() - time;
      let day = 24 * 60 * 60 * 1000;

      if (!data) {
        return fetchAndStore(bz_url);
      } else if (age >= day) {
        this.props.dispatch({ type: 'REPLACE_BUG_DATA', data })
        return fetchAndStore(bz_url);
      } else {
        return data;
      }
    })
    .then(data => this.props.dispatch({ type: 'REPLACE_BUG_DATA', data }))
    .then(() => this.props.dispatch({ type: 'UPDATE_NETWORK_STATUS', status: 'IDLE' }));
  }

  render() {
    return (
      <div>
        <PageHeader />
        <BugList />
      </div>
    );
  }
}

const mapStateToProps = (state) => ({
  bugs: state.getIn(['data', 'bugs'])
});

const mapDispatchToProps = (dispatch) => ({ dispatch });

export default connect(mapStateToProps, mapDispatchToProps)(App);

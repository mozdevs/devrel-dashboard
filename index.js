import React from 'react';
import ReactDOM from 'react-dom';

import localforage from 'localforage';
import moment from 'moment';

/* -------------------------------------------------------------------------- */

const FilterableBugList = React.createClass({
  getInitialState: function() {
    return {
      bugs: [],
      openOnly: true,
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

  handleUserInput: function(openOnly) {
    this.setState(Object.assign({}, this.state, { openOnly: openOnly }));
  },

  render: function() {
    let products = new Set(this.state.bugs.map(bug => bug.product));
    let bugLists = [];
    for (let product of products) {
      let bugs = this.state.bugs.filter(bug => bug.product === product);
      bugLists.push(<BugList openOnly={this.state.openOnly} bugs={bugs} product={product} key={product} />);
    }

    return (
      <div>
        <FilterBar openOnly={this.state.openOnly} onUserInput={this.handleUserInput} />
        {bugLists}
      </div>
    );
  }
});

const FilterBar = React.createClass({
  handleChange: function() {
    this.props.onUserInput(this.refs.openOnlyInput.checked);
  },
  render: function() {
    return (
      <form>
        <input
          type='checkbox'
          checked={this.props.openOnly}
          onChange={this.handleChange}
          ref='openOnlyInput'
        />
        {' '}
        Only show open bugs
        </form>
    );
  }
});

const BugList = React.createClass({
  render: function() {
    let rows = this.props.bugs
      .filter(bug => (!this.props.openOnly || bug.is_open))
      .map(bug => <BugRow bug={bug} key={bug.id} />);

    let totalBugCount = this.props.bugs.length;
    let openBugCount = this.props.bugs.filter(bug => bug.is_open).length;

    // Bail if nothing to show
    if (rows.length === 0) {
      return null;
    }

    return (
      <div>
        <h2>{this.props.product} (Open: {openBugCount} / {totalBugCount})</h2>
        <table>
          <thead>
            <tr>
              <td>ID</td>
              <td>Summary</td>
              <td>Status</td>
              <td>Resolution</td>
              <td>Component</td>
              <td>Created</td>
            </tr>
          </thead>
          <tbody>
            {rows}
          </tbody>
        </table>
      </div>
    );
  }
});

const BugRow = React.createClass({
  render: function() {
    let age = moment(this.props.bug.creation_time);
    return (
      <tr>
        <td><a href={"https://bugzilla.mozilla.org/show_bug.cgi?id=" + this.props.bug.id} target="_blank">{this.props.bug.id}</a></td>
        <td>{this.props.bug.summary}</td>
        <td>{this.props.bug.status}</td>
        <td>{this.props.bug.resolution}</td>
        <td>{this.props.bug.component}</td>
        <td data-unixtime={age.unix()}>{age.fromNow(true)}</td>
      </tr>
    );
  }
})

/* -------------------------------------------------------------------------- */

ReactDOM.render(
  <FilterableBugList />,
  document.getElementById('app')
)

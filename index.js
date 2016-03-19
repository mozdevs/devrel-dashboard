import React from 'react';
import ReactDOM from 'react-dom';

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

    if ('caches' in window) {
      caches.open('bzcache')
      .then(cache => cache.match(bz_url))
      .then(result => { return result ? result.json() : undefined })
      .then(json => json ? setState(json) : undefined)

      // Promise.all([caches.open('bzcache'), fetch(bz_url)])
      // .then(([cache, result]) => {
      //   cache.put(bz_url, result.clone());
      //   return result.json();
      // })
      // .then(json => setState(json))
      // .then(() => console.log("Done with fetch"))
    } else {
      fetch(bz_url)
      .then(result => result.json())
      .then(json => setState(json))
    }
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

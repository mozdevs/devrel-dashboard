import React from 'react';
import ReactDOM from 'react-dom';

import moment from 'moment';

/* -------------------------------------------------------------------------- */

const FilterableBugList = React.createClass({
  getInitialState: function() {
    return {
      bugs: [],
      openOnly: false
    }
  },

  componentDidMount: function() {
    fetch('/DATA_SNAPSHOT.json')
    .then(res => res.json())
    .then(data => this.setState(Object.assign({}, this.state, { bugs: data.bugs })));
  },

  handleUserInput: function(openOnly) {
    this.setState({ openOnly: openOnly });
  },

  render: function() {
    return (
      <div>
        <FilterBar openOnly={this.state.openOnly} onUserInput={this.handleUserInput} />
        <BugList openOnly={this.state.openOnly} bugs={this.state.bugs} />
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
      .map(bug => <BugRow bug={bug} />);

    return (
      <div>
        <h2>Displaying {rows.length} Bugs</h2>
        <table>
          <thead>
            <tr>
              <td>ID</td>
              <td>Summary</td>
              <td>Status</td>
              <td>Resolution</td>
              <td>Product</td>
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
        <td>{this.props.bug.product}</td>
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

import React from 'react';

const FilterBar = React.createClass({
  handleChange: function() {
    this.props.onUserInput(this.refs.openOnlyInput.checked);
  },
  render: function() {
    return (
      <form>
        <label>
          <input type='checkbox' checked={this.props.openOnly} onChange={this.handleChange} ref='openOnlyInput' />
          {' '}
          Only show open bugs
        </label>
      </form>
    );
  }
});

export default FilterBar;

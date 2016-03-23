import React from 'react';
import moment from 'moment';
import orderBy from 'lodash/orderBy';
import { Table, sortColumn } from 'reactabular';

const BugList = React.createClass({
  getInitialState: function() {
    let columns = [
      { property: 'id', header: 'ID', cell: (id) => (
          <a href={`https://bugzilla.mozilla.org/show_bug.cgi?id=${id}`} target="_blank">{id}</a>
      )},
      { property: 'summary', header: 'Summary' },
      { property: 'status', header: 'Status' },
      { property: 'resolution', header: 'Resolution' },
      { property: 'product', header: 'Product' },
      { property: 'component', header: 'Component' },
      { property: 'creation_time', header: 'Age',
          cell: (date) => moment(date).fromNow(true) }
    ];

    return { sortingColumn: undefined, columns: columns}
  },

  render: function() {
    let columns = this.state.columns;

    let row = (row) => ({ "data-open": row.is_open });

    let bugs = this.props.bugs;
    if (this.props.openOnly) {
      bugs = bugs.filter(bug => bug.is_open);
    }

    let totalBugs = this.props.bugs.length;
    let openBugs = this.props.bugs.filter(bug => bug.is_open).length;

    let columnNames = {
      onClick: (column) => {
        sortColumn(
          this.state.columns,
          column,
          this.setState.bind(this)
        );
      },
    }


    let data = sortColumn.sort(bugs, this.state.sortingColumn, orderBy);

    return (
      <div>
        <h1>DevAdvocacy Bugs (Open: {openBugs} / {totalBugs})</h1>
        <Table columns={columns} row={row} data={data} columnNames={columnNames} />
      </div>
    )
  }
});

export default BugList;

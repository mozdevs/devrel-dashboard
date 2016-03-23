import React from 'react';
import { connect } from 'react-redux';
import moment from 'moment';
import orderBy from 'lodash/orderBy';
import { Table } from 'reactabular';

const BugList = (props) => {
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

  columns.forEach((col) => {
    if (col.property == props.sortCol) {
      col.headerClass = 'sort-' + props.sortDir;
    }
  });

  let columnNames = {
    onClick: (column) => props.toggleSort(column)
  }

  let row = (row) => ({ "data-open": row.is_open });

  let bugs = props.bugs;
  if (!props.showClosed) {
    bugs = bugs.filter(bug => bug.is_open);
  }

  let totalBugs = props.bugs.length;
  let openBugs = props.bugs.filter(bug => bug.is_open).length;

  let data = orderBy(bugs, [props.sortCol], [props.sortDir]);

  return (
    <div>
      <h1>DevAdvocacy Bugs (Open: {openBugs} / {totalBugs})</h1>
      <Table columns={columns} row={row} data={data} columnNames={columnNames} />
    </div>
  )
};

const mapStateToProps = (state) => ({
  showClosed: state.get('showClosed'),
  sortCol: state.getIn(['sort', 'column']),
  sortDir: state.getIn(['sort', 'direction']),
});

const mapDispatchToProps = (dispatch) => ({
  toggleSort: (column) => dispatch({ type: 'TOGGLE_SORT_COLUMN', column: column.property })
})

export default connect(mapStateToProps, mapDispatchToProps)(BugList);

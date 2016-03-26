import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import moment from 'moment';
import { Table } from 'reactabular';
import Immutable from 'immutable';
import { createSelector } from 'reselect';
import { sortColumn } from '../actions';

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
        cell: (date) => moment(date).fromNow(true)
    }
  ];

  columns.forEach((col) => {
    if (col.property == props.sortCol) {
      col.headerClass = 'sort-' + props.sortDir;
    }
  });

  let row = (row) => ({ "data-open": row.get('is_open') });

  let columnNames = {
    onClick: (column) => props.toggleSort(column)
  }

  let body;
  if (props.bugList.count() === 0) {
    body = <p><em>No open bugs in this product.</em></p>;
  } else {
    body = <Table columns={columns} row={row} data={props.bugList} columnNames={columnNames} />
  }

  return (
    <div>
      <h1>DevAdvocacy Bugs</h1>
      {body}
    </div>
  );
}

BugList.propTypes = {
  bugList: PropTypes.oneOfType([
    PropTypes.array,
    PropTypes.instanceOf(Immutable.Iterable),
  ]).isRequired,
  toggleSort: PropTypes.func.isRequired,
  sortDir: PropTypes.string.isRequired,
  sortCol: PropTypes.string.isRequired,
}

const mapStateToProps = (state) => ({
  bugList: createSelector([
      (state) => state.get('bugs'),
      (state) => state.getIn(['meta', 'showClosed']),
      (state) => state.getIn(['meta', 'sortColumn']),
      (state) => state.getIn(['meta', 'sortDirection']),
      (state) => state.getIn(['meta', 'product']),
    ], (bugs, showClosed, sortColumn, sortDirection, product) => {
      bugs = bugs.sortBy(x => x.get(sortColumn));

      if (product) {
        bugs = bugs.filter(bug => bug.get('product') === product);
      }

      if (!showClosed) {
        bugs = bugs.filter(bug => bug.get('is_open'));
      }

      if (sortDirection === 'desc') {
        bugs = bugs.reverse();
      }

      return bugs.valueSeq();
    })(state),
  sortCol: state.getIn(['meta', 'sortColumn']),
  sortDir: state.getIn(['meta', 'sortDirection']),
});

const mapDispatchToProps = (dispatch) => ({
  toggleSort: (column) => dispatch(sortColumn(column.property))
})

export default connect(mapStateToProps, mapDispatchToProps)(BugList);

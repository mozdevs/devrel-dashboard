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

  let row = (row) => {
    let prio = row.get('whiteboard').match(/devrel:p(.)/i);

    return {
      'data-priority': (prio && prio[1].toUpperCase()) || 'untriaged',
      'data-open': row.get('is_open'),
    };
  };

  let columnNames = {
    onClick: (column) => props.toggleSort(column)
  }

  if (props.bugList.count()) {
    return <div id="main"><Table columns={columns} row={row} data={props.bugList} columnNames={columnNames} /></div>;
  } else if (props.fetching && !props.lastUpdated) {
    return <div id="main"><p style={{'textAlign': 'center'}}><em>Fetching data from Bugzilla...</em></p></div>;
  } else {
    return <div id="main"><p style={{'textAlign': 'center'}}><em>No bugs match your filters.</em></p></div>;
  }
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
      (state) => state.getIn(['meta', 'products']),
      (state) => state.getIn(['meta', 'priorities']),
    ], (bugs, showClosed, sortColumn, sortDirection, products, priorities) => {
      bugs = bugs.sort((a, b) => {
        let ax = a.get(sortColumn);
        let bx = b.get(sortColumn);

        if (typeof ax === 'string' && typeof bx === 'string') {
          ax = ax.toLowerCase();
          bx = bx.toLowerCase();
        }

        switch (sortColumn) {
          case 'product':
            if (ax !== bx) { return ax > bx ? 1 : -1; }

            let ay = a.get('component');
            let by = b.get('component');

            if (ay !== by) { return ay > by ? 1 : -1; }

            let az = a.get('id');
            let bz = b.get('id');

            if (az !== bz) { return az > bz ? -1 : 1; } // <-- Reversed

            return 0;
          case 'creation_time':
            if (ax !== bx) { return ax > bx ? -1 : 1; } // <-- Reversed
          default:
            if (ax !== bx) { return ax > bx ? 1 : -1; }

            return 0;
        }
      });

      if (!products.includes('(all)')) {
        bugs = bugs.filter(bug => products.includes(bug.get('product')));
      }

      if (!priorities.includes('(all)')) {
        bugs = bugs.filter(bug => {
          let re = /devrel:p(.)/i;
          let wb = bug.get('whiteboard');

          let match = re.exec(wb);

          return priorities.includes(match ? match[1].toUpperCase() : '(untriaged)');
        });
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
  fetching: state.getIn(['meta', 'isFetching']),
  lastUpdated: state.getIn(['meta', 'lastUpdated']),
});

const mapDispatchToProps = (dispatch) => ({
  toggleSort: (column) => dispatch(sortColumn(column.property))
})

export default connect(mapStateToProps, mapDispatchToProps)(BugList);

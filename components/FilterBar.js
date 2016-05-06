import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { toggleClosed, selectProduct, selectPriority } from '../actions';
import { createSelector } from 'reselect';

const FilterBar = (props) => {
  let productOptions = props.products.map(product => (
    <label key={product} title={product}>
      <input type='checkbox'
             value={product}
             checked={props.selectedProducts.includes(product)}
             onChange={props.onProdFilter} /> {product}
    </label>
  ));

  let priorityOptions = props.priorities.map(priority => {
    let label;
    let color = priority.color ? priority.color : 'black';

    if (priority.symbol) {
      label = (
        <span style={{ position: 'relative' }}>
          <span style={{ color: color, position: 'absolute', left: 0, bottom: '-1px' }}>{priority.symbol}</span>
          <span style={{ paddingLeft: '.8em' }}>{priority.label}</span>
        </span>
      );
    } else {
      label = (
        <span style={{ paddingLeft: '.8em' }}>{priority.label}</span>
      );
    }

    return (
      <label key={priority.value} title={priority.value}>
        <input type='checkbox'
               value={priority.value}
               checked={props.selectedPriorities.includes(priority.value)}
               onChange={props.onPrioFilter} />
        {label}
      </label>
    );
  });

  return (
    <form id="sidebar">
      <div>
        <span style={{'fontWeight': 'bold'}}>Filters</span>
      </div>

      <div>
        {productOptions}
      </div>

      <div>
        {priorityOptions}
      </div>

      <div>
        <label>
          <input type='checkbox' checked={props.showClosed} onChange={props.onChange} />
          { ' ' }
          Show closed bugs
        </label>
      </div>
    </form>
  );
};

FilterBar.propTypes = {
  showClosed: PropTypes.bool.isRequired,
  onChange: PropTypes.func.isRequired,
}

const mapStateToProps = (state) => ({
  showClosed: state.getIn(['meta', 'showClosed']),
  selectedProducts: state.getIn(['meta', 'products']),
  selectedPriorities: state.getIn(['meta', 'priorities']),

  priorities: [
    {value: '(all)', label: '(all)'},
    {value: '1', label: 'P1 – Critical ', symbol: '»', color: 'red'},
    {value: '2', label: 'P2 – Major', symbol: '›', color: 'green'},
    {value: '3', label: 'P3 – Minor'},
    {value: 'X', label: 'PX – Ignore', symbol: '✕'},
    {value: '(untriaged)', label: 'Untriaged', symbol: '?'},
  ],

  products: createSelector([
      (state) => state.get('bugs'),
    ], (bugs) => {
      return bugs.map(bug => bug.get('product')).toSet().add('(all)').sortBy(x => x.toLowerCase());
    })(state),

});

const mapDispatchToProps = (dispatch) => ({
  onChange: () => dispatch(toggleClosed()),
  onProdFilter: (event) => dispatch(selectProduct(event.target.value)),
  onPrioFilter: (event) => dispatch(selectPriority(event.target.value)),
});

export default connect(mapStateToProps, mapDispatchToProps)(FilterBar);

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
    let label = priority.length > 1 ? priority : `P${priority}`;

    return (
      <label key={priority} title={priority}>
        <input type='checkbox'
               value={priority}
               checked={props.selectedPriorities.includes(priority)}
               onChange={props.onPrioFilter} /> {label}
      </label>
    );
  });

  return (
    <form id="sidebar">
      <div>
        <span style={{'fontWeight': 'bold'}}>Filters</span>
      </div>

      <div>
        <label>
          <input type='checkbox' checked={props.showClosed} onChange={props.onChange} />
          { ' ' }
          Show closed bugs
        </label>
      </div>

      <div>
        {productOptions}
      </div>

      <div>
        {priorityOptions}
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

  priorities: ["(all)", "1", "2", "3", "X", "(untriaged)"],

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

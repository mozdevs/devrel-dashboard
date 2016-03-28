import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { toggleClosed, selectProduct } from '../actions';
import { createSelector } from 'reselect';

const FilterBar = (props) => {
  let productOptions = props.products.map(product => (
    <label key={product}>
      <input type='checkbox'
             value={product}
             checked={props.selectedProducts.includes(product)}
             onChange={props.onProdFilter} /> {product}
    </label>
  ));

  return (
    <form>
      <label>
        <input type='checkbox' checked={props.showClosed} onChange={props.onChange} />
        { ' ' }
        Show closed bugs
      </label>
      <div>
        {productOptions}
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

  products: createSelector([
      (state) => state.get('bugs'),
    ], (bugs) => {
      return bugs.map(bug => bug.get('product')).toSet().add('(all)').sort();
    })(state),
});

const mapDispatchToProps = (dispatch) => ({
  onChange: () => dispatch(toggleClosed()),
  onProdFilter: (event) => dispatch(selectProduct(event.target.value)),
});

export default connect(mapStateToProps, mapDispatchToProps)(FilterBar);

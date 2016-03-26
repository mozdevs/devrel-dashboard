import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { toggleClosed, selectProduct } from '../actions';
import { createSelector } from 'reselect';

const FilterBar = (props) => {
  let productOptions = props.products.map(product => <option value={product} key={product}>{product}</option>)

  return (
    <form>
      <label>
        <input type='checkbox' checked={props.checked} onChange={props.onChange} />
        { ' ' }
        Show closed bugs
      </label>
      <select name="productfilter" onChange={props.onProdFilter}>
        {productOptions}
      </select>
    </form>
  );
};

FilterBar.propTypes = {
  checked: PropTypes.bool.isRequired,
  onChange: PropTypes.func.isRequired,
}

const mapStateToProps = (state) => ({
  checked: state.getIn(['meta', 'showClosed']),
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

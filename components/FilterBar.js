import React, { PropTypes } from 'react';
import { connect } from 'react-redux';

const FilterBar = (props) => (
  <form>
    <label>
      <input type='checkbox' checked={props.checked} onChange={props.onChange} />
      { ' ' }
      Show closed bugs
    </label>
  </form>
);

FilterBar.propTypes = {
  checked: PropTypes.bool.isRequired,
  onChange: PropTypes.func.isRequired,
}

const mapStateToProps = (state) => ({ checked: state.get('showClosed') });
const mapDispatchToProps = (dispatch) => ({ onChange: () => dispatch({ type: 'TOGGLE_SHOW_CLOSED' }) });

export default connect(mapStateToProps, mapDispatchToProps)(FilterBar);

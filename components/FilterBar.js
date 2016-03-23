import React from 'react';
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

const mapStateToProps = (state) => ({ checked: state.get('showClosed') });
const mapDispatchToProps = (dispatch) => ({ onChange: () => dispatch({ type: 'TOGGLE_SHOW_CLOSED' }) });

export default connect(mapStateToProps, mapDispatchToProps)(FilterBar);

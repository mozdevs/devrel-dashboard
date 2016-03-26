import React, { PropTypes } from 'react';
import { connect } from 'react-redux';

const NetworkStatus = (props) => {
  if (props.fetching) {
    return <p><em>Fetching data from Bugzilla...</em></p>;
  } else {
    return <p></p>;
  }
};

NetworkStatus.propTypes = {
  fetching: PropTypes.bool.isRequired,
}

const mapStateToProps = (state) => ({
  fetching: state.getIn(['meta', 'isFetching']),
});

const mapDispatchToProps = (dispatch) => ({
});

export default connect(mapStateToProps, mapDispatchToProps)(NetworkStatus);

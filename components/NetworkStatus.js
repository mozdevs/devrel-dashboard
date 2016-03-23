import React, { PropTypes } from 'react';
import { connect } from 'react-redux';

const NetworkStatus = (props) => {
  switch (props.status) {
    case 'INIT':
      return <span>Initializing...</span>;
    case 'LOAD_CACHE':
      return <span>Loading data from cache...</span>;
    case 'LOAD_NETWORK':
      return <span>Loading data from Bugzilla...</span>;
    case 'IDLE':
      return <span>Network idle.</span>;
    case 'ERROR':
      return <span>Error fetching.</span>;
    default:
      return <span>Unhandled network state, please refresh the page.</span>;
  }
};

NetworkStatus.propTypes = {
  status: PropTypes.string.isRequired,
}

const mapStateToProps = (state) => ({
  status: state.getIn(['network', 'status']),
});

const mapDispatchToProps = (dispatch) => ({
});

export default connect(mapStateToProps, mapDispatchToProps)(NetworkStatus);

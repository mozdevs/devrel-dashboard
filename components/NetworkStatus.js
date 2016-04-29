import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import moment from 'moment';
import { fetchBugs } from '../actions'


const NetworkStatus = (props) => {
  if (props.fetching) {
    return <p>Fetching data from Bugzilla...</p>;
  } else if (props.lastUpdated === undefined) {
    return <p>Initializing...</p>
  } else {
    return (
      <p>
        Last updated <b title={moment(props.lastUpdate).toString()}>
          {moment(props.lastUpdated).fromNow()}
        </b> <button onClick={props.refresh}>
          update now
        </button>
      </p>
    );
  }
};

NetworkStatus.propTypes = {
  fetching: PropTypes.bool.isRequired,
}

const mapStateToProps = (state) => ({
  fetching: state.getIn(['meta', 'isFetching']),
  lastUpdated: state.getIn(['meta', 'lastUpdated']),
});

const mapDispatchToProps = (dispatch) => ({
  refresh: () => dispatch(fetchBugs()),
});

export default connect(mapStateToProps, mapDispatchToProps)(NetworkStatus);

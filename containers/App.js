import React from 'react';
import { connect } from 'react-redux';
import localforage from 'localforage';

import PageHeader from '../components/PageHeader';
import FilterBar from '../components/FilterBar';
import BugList from '../components/BugList';

import { fetchBugsIfNeeded } from '../actions';

class App extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidMount() {
    let { dispatch } = this.props;
    dispatch(fetchBugsIfNeeded());
  }

  render() {
    return (
      <div>
        <PageHeader />
        <FilterBar />
        <BugList />
      </div>
    );
  }
}

const mapStateToProps = (state) => ({
  bugs: state.getIn(['data', 'bugs'])
});

const mapDispatchToProps = (dispatch) => ({ dispatch });

export default connect(mapStateToProps, mapDispatchToProps)(App);

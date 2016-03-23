import React from 'react';
import FilterBar from './FilterBar';
import NetworkStatus from './NetworkStatus';

const PageHeader = (props) => (
  <div>
    <NetworkStatus />
    <FilterBar />
  </div>
);

export default PageHeader;

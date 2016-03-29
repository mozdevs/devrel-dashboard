import React from 'react';
import NetworkStatus from './NetworkStatus';

const PageHeader = (props) => (
  <div id="header">
    <h1>Mozilla DevRel Dashboard</h1>
    <NetworkStatus />
  </div>
);

export default PageHeader;

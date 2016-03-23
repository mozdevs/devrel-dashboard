import React from 'react';
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import { createStore } from 'redux';

import App from './components/App';

import reducer from './reducers';
let store = createStore(reducer, undefined,
    window.devToolsExtension ? window.devToolsExtension() : undefined);

function render(AppInstance = App) {
  ReactDOM.render(
    <Provider store={store}>
      <AppInstance />
    </Provider>,
    document.getElementById('app')
  )
}

render();

if (module.hot) {
  module.hot.accept('./components/App.js',
    () => render(require('./components/App').default));

  module.hot.accept('./reducers',
    () => store.replaceReducer(require('./reducers').default));
}

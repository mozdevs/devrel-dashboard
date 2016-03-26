import React from 'react';
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import { createStore, compose, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';

import App from './containers/App';

import reducer from './reducers';

let store = createStore(
  reducer,
  undefined,
  compose(
    applyMiddleware(thunk),
    window.devToolsExtension ? window.devToolsExtension() : f => f
  )
);

function render(AppInstance = App) {
  window.store = store;
  ReactDOM.render(
    <Provider store={store}>
      <AppInstance />
    </Provider>,
    document.getElementById('app')
  )
}

render();

if (module.hot) {
  module.hot.accept('./containers/App.js',
    () => render(require('./containers/App').default));

  module.hot.accept('./reducers',
    () => store.replaceReducer(require('./reducers').default));
}

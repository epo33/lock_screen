part of lock_screen;

class _DialogNavigationObserver {
  _DialogNavigationObserver(this.dialog) {
    _ObserveNavigation.addObserver(this);
  }

  final _LockScreenDialog dialog;

  bool get dialogClosed => _closed;

  bool get canCloseDialog => _routeStack.isEmpty;

  void dispose() {
    _ObserveNavigation.removeObserver(this);
  }

  void didPush(Route route) {
    if (_dialogRoute == null) {
      _dialogRoute = route;
    } else {
      _routeStack.add(route);
    }
  }

  void didPop(Route route) {
    if (route == _dialogRoute) {
      _closed = true;
    } else {
      _routeStack.remove(route);
      dialog.lockStateChange.value++;
    }
  }

  // The very first route pushed since instance creation
  Route? _dialogRoute;
  // true when _dialogRoute has been poped
  bool _closed = false;
  // The route pushed after _dialogRoute
  final _routeStack = <Route>[];
}

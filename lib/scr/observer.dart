part of lock_screen;

class _ObserveNavigation extends NavigatorObserver {
  _ObserveNavigation._();

  factory _ObserveNavigation.create() => _instance ??= _ObserveNavigation._();

  static void addObserver(_DialogNavigationObserver observer) {
    _checkMounted();
    assert(
      !_instance!._lockObserverList,
      "Can't add observers during navigation operations",
    );
    _instance!._observers.add(observer);
  }

  static void removeObserver(_DialogNavigationObserver observer) {
    _checkMounted();
    assert(
      !_instance!._lockObserverList,
      "Can't remove observers during navigation operations",
    );
    _instance!._observers.remove(observer);
  }

  static void _checkMounted() {
    var error = "";
    if (_instance == null) {
      error = "LockScreen.observer has not been used.\n";
    } else if (_instance!._routes.isEmpty) {
      error =
          "LockScreen.observer has not been added in your app navigator observers.\n";
    } else {
      return;
    }
    throw StateError(
      """
$error
To use LockScreen, you must register LockScreen.observer in your app navigator observers as this :\n

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [LockScreen.observer],
      title: 'My App',
      home: Container(),
    );
  }
}

""",
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _addRoute(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _removeRoute(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _removeRoute(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _addRoute(newRoute);
    _removeRoute(oldRoute);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {}

  @override
  void didStopUserGesture() {}

  void _addRoute(route) {
    _routes.add(route);
    assert(!_lockObserverList);
    _lockObserverList = true;
    try {
      for (final obs in _observers) {
        obs.didPush(route);
      }
    } finally {
      _lockObserverList = false;
    }
  }

  void _removeRoute(route) {
    _routes.remove(route);
    assert(!_lockObserverList);
    _lockObserverList = true;
    try {
      for (final obs in _observers) {
        obs.didPop(route);
      }
    } finally {
      _lockObserverList = false;
    }
  }

  static _ObserveNavigation? _instance;
  final _observers = <_DialogNavigationObserver>[];
  final _routes = <Route>[];
  bool _lockObserverList = false;
}

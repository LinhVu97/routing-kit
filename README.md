# FidraRouting

Routing library for iOS (SwiftUI + `NavigationStack`), inspired by Jetpack Compose Navigation.

## Features

- Single `routes()` block: screen name, deeplink, and view per route
- `NavigationStack` navigation with middleware support
- Built-in deeplink handling via `present()` or `handleDeepLink(_:)`
- Dialog async/await API (similar to GetX `Get.dialog()`)
- Ad and analytics middleware

## Installation

```swift
// File -> Add Packages...
// url: "https://gitlab.volio.vn/fidra/libs/fidra-routing-swift", from: "1.0.0"
```

## Usage

### 1. Define routes (recommended — `RouteGraph`)

Declare **view + screenName + deeplink** in one `routes()` block:

```swift
enum AppRouter: RouteGraph {
    case splash
    case home
    case profile(String)

    static func routes() -> [RouteDefinition<AppRouter>] {
        routeGraph {
            route(.splash, screenName: "splash") { SplashScreen() }
                .deepLink("myapp://splash")

            route(.home, screenName: "home") { HomeScreen() }
                .deepLink("myapp://home")

            route(AppRouter.profile, screenName: "profile") { id in
                ProfileScreen(id: id)
            }
            .deepLink("myapp://profile/{id}") { args in
                args["id"].map(AppRouter.profile)
            }
        }
    }
}
```

- `screenName` is optional — defaults to the enum case name.
- `body` and `screenName` are provided automatically by `RouteGraph`.

### 2. Router setup

```swift
@MainActor
final class AppRouterHolder {
    static let shared = AppRouterHolder()
    let router: FidraRoutingProvider<AppRouter, ExampleDialogType>

    init() {
        router = FidraRoutingProvider(rootScreen: .splash)
        router.loadDestinations()

        router.addMiddleware(AnalyticScreenMiddleware(enabledLogEvent: true) { prev, curr, next in
            print(prev, curr, next)
        })
    }
}
```

### 3. App entry

`present()` returns `NavigationStack` and handles deeplinks automatically:

```swift
@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            AppRouterHolder.shared.router.present()
        }
    }
}
```

Disable automatic deeplink handling if needed:

```swift
router.present(handleDeepLinksAutomatically: false)
```

Handle deeplinks manually:

```swift
router.handleDeepLink(url)
router.handleDeepLink(url, options: .init(popUpToRoot: true, launchSingleTop: true))
```

### 4. Navigation

```swift
router.push(to: .home)
router.push(to: .profile("123"), animated: false)
router.pop()
router.pop(2)
router.popTo(to: .splash)
router.popToRoot()
router.replace(destination: .home)
router.setRoot(destinations: [.splash, .home])
router.pushOrPopTo(to: .home)
```

### 5. Dialog (async/await)

```swift
let result = await router.showDialogViewAsync(
    MyDialogView(),
    viewId: .custom,
    resultType: String.self
)

await router.showDialogViewAsync(MyDialogView(), viewId: .custom)

router.dismissDialogWithResult("confirmed")
router.dismissDialog()
```

## Alternative: manual deeplink graph

For enums that are not `RouteGraph`, register deeplinks manually:

```swift
enum AppRouter: Routable {
    case home
    case profile(String)

    var body: some View {
        switch self {
        case .home: HomeScreen()
        case .profile(let id): ProfileScreen(id: id)
        }
    }
}

let router = FidraRoutingProvider<AppRouter, DialogType>(rootScreen: .home)
router.navigationGraph {
    composable(.home, deepLinks: {
        navDeepLink("myapp://home")
    })
    composable(deepLinks: {
        navDeepLink("myapp://profile/{id}") { args in
            args["id"].map(AppRouter.profile)
        }
    })
}
router.present()
```

## Legacy `Routable`

```swift
enum OldRouter: Routable {
    case home

    var body: some View { HomeScreen() }
    var screenName: String { "home" }
}

let router = FidraRoutingProvider<OldRouter, DialogType>(rootScreen: .home)
router.present()
```

## Requirements

- iOS 16.0+
- Swift 5.9+
- SwiftUI

## License

Copyright © 2025 Fidra. All rights reserved.

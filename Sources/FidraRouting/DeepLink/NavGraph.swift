//
//  NavGraph.swift
//  FidraRouting
//

import Foundation

public struct DeepLinkNavigationOptions {
    public var popUpToRoot: Bool
    public var launchSingleTop: Bool

    public init(popUpToRoot: Bool = false, launchSingleTop: Bool = false) {
        self.popUpToRoot = popUpToRoot
        self.launchSingleTop = launchSingleTop
    }
}

struct ResolvedDeepLink<R: Routable> {
    let uriPattern: String
    let resolve: (DeepLinkArguments) -> R?
}

public struct NavDeepLinkPattern<R: Routable> {
    let uriPattern: String
    let mapper: ((DeepLinkArguments) -> R?)?
}

public struct ComposableDestination<R: Routable> {
    let deepLinks: [ResolvedDeepLink<R>]
}

@resultBuilder
public enum NavDeepLinkBuilder<R: Routable> {
    public static func buildBlock(_ components: NavDeepLinkPattern<R>...) -> [NavDeepLinkPattern<R>] {
        Array(components)
    }
}

/// Route enum declares view, screenName, and deeplink together — like `composable<Route>(deepLinks = ...)`.
public protocol RoutableWithDestinations: Routable {
    static func destinations() -> [ComposableDestination<Self>]
}

@resultBuilder
public enum NavigationGraphBuilder<R: Routable> {
    public static func buildBlock(_ components: ComposableDestination<R>...) -> [ComposableDestination<R>] {
        Array(components)
    }
}

/// Declare deeplink for a destination, similar to `navDeepLink { uriPattern = "..." }` in Compose.
public func navDeepLink<R: Routable>(_ uriPattern: String) -> NavDeepLinkPattern<R> {
    NavDeepLinkPattern(uriPattern: uriPattern, mapper: nil)
}

public func navDeepLink<R: Routable>(_ uriPattern: String, destination: R) -> NavDeepLinkPattern<R> {
    NavDeepLinkPattern(uriPattern: uriPattern, mapper: { _ in destination })
}

public func navDeepLink<R: Routable>(
    _ uriPattern: String,
    destination: @escaping (DeepLinkArguments) -> R?
) -> NavDeepLinkPattern<R> {
    NavDeepLinkPattern(uriPattern: uriPattern, mapper: destination)
}

/// Declare a destination with deeplinks, similar to `composable<Route>(deepLinks = ...) { ... }`.
public func composable<R: Routable>(
    _ route: R,
    @NavDeepLinkBuilder<R> deepLinks: () -> [NavDeepLinkPattern<R>] = { [] }
) -> ComposableDestination<R> {
    let patterns = deepLinks()
    let resolved = patterns.map { pattern in
        ResolvedDeepLink(uriPattern: pattern.uriPattern) { args in
            pattern.mapper?(args) ?? route
        }
    }
    return ComposableDestination(deepLinks: resolved)
}

/// Declare a parameterized destination with deeplinks.
public func composable<R: Routable>(
    @NavDeepLinkBuilder<R> deepLinks: () -> [NavDeepLinkPattern<R>]
) -> ComposableDestination<R> {
    let resolved = deepLinks().compactMap { pattern -> ResolvedDeepLink<R>? in
        guard let mapper = pattern.mapper else { return nil }
        return ResolvedDeepLink(uriPattern: pattern.uriPattern, resolve: mapper)
    }
    return ComposableDestination(deepLinks: resolved)
}

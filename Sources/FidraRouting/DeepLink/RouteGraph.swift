//
//  RouteGraph.swift
//  FidraRouting
//

import SwiftUI

public struct RouteDefinition<R: RouteGraph> {
    let screenName: String
    let presentationStyle: RoutePresentationStyle
    let matches: (R) -> Bool
    let buildView: (R) -> AnyView
    let deepLinks: [ResolvedDeepLink<R>]
}

public final class RouteRegistry<R: RouteGraph> {
    private let definitions: [RouteDefinition<R>]

    init(definitions: [RouteDefinition<R>]) {
        self.definitions = definitions
    }

    func view(for route: R) -> AnyView {
        for definition in definitions where definition.matches(route) {
            return definition.buildView(route)
        }
        return AnyView(EmptyView())
    }

    func screenName(for route: R) -> String {
        for definition in definitions where definition.matches(route) {
            return definition.screenName
        }
        return "unknown"
    }

    func presentationStyle(for route: R) -> RoutePresentationStyle {
        for definition in definitions where definition.matches(route) {
            return definition.presentationStyle
        }
        return .stack
    }

    var resolvedDeepLinks: [ResolvedDeepLink<R>] {
        definitions.flatMap(\.deepLinks)
    }
}

public struct RouteDefinitionBuilder<R: RouteGraph> {
    private let screenName: String
    private let presentationStyle: RoutePresentationStyle
    private let matches: (R) -> Bool
    private let buildView: (R) -> AnyView
    private let fallbackRoute: R?
    private var deepLinkPatterns: [NavDeepLinkPattern<R>] = []

    fileprivate init(
        screenName: String,
        presentationStyle: RoutePresentationStyle,
        matches: @escaping (R) -> Bool,
        buildView: @escaping (R) -> AnyView,
        fallbackRoute: R? = nil
    ) {
        self.screenName = screenName
        self.presentationStyle = presentationStyle
        self.matches = matches
        self.buildView = buildView
        self.fallbackRoute = fallbackRoute
    }

    public func deepLink(_ uriPattern: String) -> RouteDefinitionBuilder<R> {
        var copy = self
        copy.deepLinkPatterns.append(NavDeepLinkPattern(uriPattern: uriPattern, mapper: nil))
        return copy
    }

    public func deepLink(
        _ uriPattern: String,
        destination: @escaping (DeepLinkArguments) -> R?
    ) -> RouteDefinitionBuilder<R> {
        var copy = self
        copy.deepLinkPatterns.append(NavDeepLinkPattern(uriPattern: uriPattern, mapper: destination))
        return copy
    }

    fileprivate func build() -> RouteDefinition<R> {
        let resolved = deepLinkPatterns.map { pattern in
            ResolvedDeepLink(uriPattern: pattern.uriPattern) { args in
                if let mapper = pattern.mapper {
                    return mapper(args)
                }
                return fallbackRoute
            }
        }

        return RouteDefinition(
            screenName: screenName,
            presentationStyle: presentationStyle,
            matches: matches,
            buildView: buildView,
            deepLinks: resolved
        )
    }
}

@resultBuilder
public enum RouteGraphBuilder<R: RouteGraph> {
    public static func buildBlock(_ components: RouteDefinitionBuilder<R>...) -> [RouteDefinition<R>] {
        components.map { $0.build() }
    }
}

/// Static route: view + deeplink in one block.
public func route<R: RouteGraph, V: View>(
    _ route: R,
    screenName: String? = nil,
    presentation: RoutePresentationStyle = .stack,
    @ViewBuilder content: @escaping () -> V
) -> RouteDefinitionBuilder<R> {
    RouteDefinitionBuilder(
        screenName: screenName ?? RouteMetadata.caseName(for: route),
        presentationStyle: presentation,
        matches: { $0 == route },
        buildView: { _ in AnyView(content()) },
        fallbackRoute: route
    )
}

/// Parameterized route: view + deeplink in one block.
public func route<R: RouteGraph, V: View, Arg>(
    _ constructor: @escaping (Arg) -> R,
    screenName: String? = nil,
    presentation: RoutePresentationStyle = .stack,
    @ViewBuilder content: @escaping (Arg) -> V
) -> RouteDefinitionBuilder<R> {
    let sample = constructor(RouteMetadata.placeholder(for: Arg.self))
    let resolvedScreenName = screenName ?? RouteMetadata.caseName(for: sample)

    return RouteDefinitionBuilder(
        screenName: resolvedScreenName,
        presentationStyle: presentation,
        matches: { RouteMetadata.caseName(for: $0) == resolvedScreenName },
        buildView: { route in
            guard let value = RouteMetadata.firstAssociatedValue(from: route, as: Arg.self) else {
                return AnyView(EmptyView())
            }
            return AnyView(content(value))
        }
    )
}

/// Declare the full route graph in one block — view, screenName, and deeplink per `route(...)`.
public protocol RouteGraph: Routable, FidraPresentationStyleProviding {
    static func routes() -> [RouteDefinition<Self>]
}

/// Result-builder helper for `RouteGraph.routes()`.
public func routeGraph<R: RouteGraph>(
    @RouteGraphBuilder<R> _ builder: () -> [RouteDefinition<R>]
) -> [RouteDefinition<R>] {
    builder()
}

public extension RouteGraph {
    var body: some View {
        Self.registry.view(for: self)
    }

    var screenName: String {
        Self.registry.screenName(for: self)
    }

    var presentationStyle: RoutePresentationStyle {
        Self.registry.presentationStyle(for: self)
    }

    static var registry: RouteRegistry<Self> {
        RouteRegistry(definitions: routes())
    }
}

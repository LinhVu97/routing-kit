//
//  FidraRoutingProvider+DeepLink.swift
//  FidraRouting
//

import SwiftUI

public extension FidraRoutingProvider where R: RouteGraph {

    /// Loads deeplink definitions from `RouteGraph.routes()`. Call once after init.
    func loadDestinations() {
        deepLinkDefinitions = R.registry.resolvedDeepLinks
    }
}

public extension FidraRoutingProvider {

    /// Register a navigation graph manually (legacy).
    func navigationGraph(@NavigationGraphBuilder<R> _ builder: () -> [ComposableDestination<R>]) {
        deepLinkDefinitions = builder().flatMap(\.deepLinks)
    }

    func resolveDeepLink(_ url: URL) -> R? {
        for definition in deepLinkDefinitions {
            guard let arguments = DeepLinkMatcher.match(url: url, pattern: definition.uriPattern) else {
                continue
            }
            if let destination = definition.resolve(arguments) {
                return destination
            }
        }
        return nil
    }

    @discardableResult
    func handleDeepLink(
        _ url: URL,
        options: DeepLinkNavigationOptions = .init(),
        animated: Bool = true
    ) -> Bool {
        guard let destination = resolveDeepLink(url) else { return false }

        if options.launchSingleTop, screenStack.last == destination {
            return true
        }

        nextScreen = destination

        executeMiddlewares(navigationAction: .deepLink, nextScreen: destination) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: animated) {
                if options.popUpToRoot, let root = self.screenStack.first {
                    self.screenStack = [root, destination]
                } else {
                    self.screenStack.append(destination)
                }
            }
            self.nextScreen = nil
        }

        return true
    }

    @discardableResult
    func handleDeepLink(
        _ userActivity: NSUserActivity,
        options: DeepLinkNavigationOptions = .init(),
        animated: Bool = true
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        return handleDeepLink(url, options: options, animated: animated)
    }
}

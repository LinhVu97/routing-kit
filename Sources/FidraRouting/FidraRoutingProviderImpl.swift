//
//  FidraRoutingProviderImpl.swift
//  FidraRouting
//
//  Created by nguyen anh tuan on 03/08/2025.
//

import SwiftUI

public extension FidraRoutingProvider {

    func push(to destination: R, inTab: Bool = false, animated: Bool = true) {
        if inTab, let currentTab = currentTab {
            var stack = tabStacks[currentTab] ?? []
            if stack.last?.screenName == destination.screenName { return }

            executeMiddlewares(navigationAction: .push, nextScreen: destination) { [weak self] in
                guard let self else { return }
                self.performNavigation(animated: animated) {
                    stack.append(destination)
                    self.tabStacks[currentTab] = stack
                }
            }
            return
        }
        if nextScreen == destination { return }
        if screenStack.last?.screenName == destination.screenName { return }

        nextScreen = destination
        executeMiddlewares(navigationAction: .push, nextScreen: destination) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: animated) {
                self.screenStack.append(destination)
            }
            self.nextScreen = nil
        }
    }

    func pop(animated: Bool = true, inTab: Bool = false, completion: (() -> Void)? = nil) {
        if inTab, let currentTab = currentTab, var stack = tabStacks[currentTab], !stack.isEmpty {
            let nextVisible = upcomingTabScreenAfterPop(tab: currentTab)
            executeMiddlewares(navigationAction: .pop, nextScreen: nextVisible) { [weak self] in
                guard let self else { return }
                self.performNavigation(animated: animated) {
                    stack.removeLast()
                    self.tabStacks[currentTab] = stack.isEmpty ? nil : stack
                }
                completion?()
            }
            return
        }
        guard screenStack.count > 1 else {
            completion?()
            return
        }

        executeMiddlewares(navigationAction: .pop, nextScreen: nil) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: animated) {
                self.screenStack.removeLast()
            }
            completion?()
        }
    }

    func popWithPushController(animated: Bool = true, completion: (() -> Void)? = nil) {
        pop(animated: animated, completion: completion)
    }

    func pop(_ count: Int, animated: Bool = true) {
        guard count > 0, screenStack.count > count else { return }

        let targetIndex = screenStack.count - count - 1
        guard targetIndex >= 0 else { return }

        let nextScreen = screenStack[targetIndex]
        executeMiddlewares(navigationAction: .popCount, nextScreen: nextScreen) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: animated) {
                self.screenStack = Array(self.screenStack.prefix(targetIndex + 1))
            }
        }
    }

    func pushOrPopTo(to destination: R, animated: Bool = true) {
        if screenStack.last == destination { return }
        if screenStack.contains(where: { $0.screenName == destination.screenName }) {
            popTo(to: destination, animated: animated)
        } else {
            push(to: destination, animated: animated)
        }
    }

    func popTo(to destination: R, animated: Bool = true) {
        guard let index = screenStack.firstIndex(where: { $0.screenName == destination.screenName }) else { return }

        executeMiddlewares(navigationAction: .popTo, nextScreen: destination) { [weak self] in
            guard let self else { return }
            var newStack = Array(self.screenStack.prefix(index + 1))
            newStack[index] = destination
            self.performNavigation(animated: animated) {
                self.screenStack = newStack
            }
        }
    }

    func popToRoot(animated: Bool = true) {
        guard screenStack.count > 1 else { return }

        let nextScreen = screenStack.first
        executeMiddlewares(navigationAction: .popToRoot, nextScreen: nextScreen) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: animated) {
                self.screenStack = Array(self.screenStack.prefix(1))
            }
        }
    }

    func replace(destination: R, animated: Bool = true) {
        guard !screenStack.isEmpty else { return }

        executeMiddlewares(navigationAction: .replace, nextScreen: destination) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: animated) {
                self.screenStack.removeLast()
                self.screenStack.append(destination)
            }
        }
    }

    func replace(destinations: [R], animated: Bool = true) {
        guard !destinations.isEmpty else { return }

        let targetScreenNames = destinations.map(\.screenName)
        let resetContainer = shouldResetContainerState(for: destinations)
        if targetScreenNames == screenStack.map(\.screenName) {
            if resetContainer { clearContainerNavigationState() }
            return
        }

        let nextScreen = destinations.last
        executeMiddlewares(navigationAction: .replace, nextScreen: nextScreen) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: animated) {
                self.screenStack = destinations
                if resetContainer { self.clearContainerNavigationState() }
            }
        }
    }

    func setRoot(destinations: [R], animated: Bool = true) {
        replace(destinations: destinations, animated: animated)
    }

    /// Onboarding pager / in-flow screen change — runs middleware **and** appends to `screenStack`.
    func onChangeScreen(_ destination: R) {
        if screenStack.last == destination { return }

        executeMiddlewares(navigationAction: .push, nextScreen: destination) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: false) {
                self.screenStack.append(destination)
            }
        }
    }

    /// Seed tab + logical root screen without middleware (e.g. first mount after `setRoot(home)`).
    public func setEmbeddedTab(_ tab: AnyHashable, destination: R) {
        currentTab = tab
        embeddedScreenRoute = destination
    }

    /// Tab switch — updates logical screen state and runs middleware (tracking / ads).
    /// `destination` is the tab root; `next` in middleware is tab stack top if any.
    public func selectTab(_ tab: AnyHashable, destination: R) {
        let nextVisible = visibleTabScreen(for: tab, fallback: destination) ?? destination
        performEmbeddedScreenChange(
            tab: tab,
            tabRoot: destination,
            nextVisible: nextVisible,
            from: visibleScreenRoute(stackCurrent: screenStack.last)
        )
    }

    /// Tab / embedded logical screen change — prefer `selectTab` when switching TabView tabs.
    public func onEmbeddedScreenChange(_ destination: R, from previous: R? = nil) {
        performEmbeddedScreenChange(
            tab: currentTab,
            tabRoot: destination,
            nextVisible: destination,
            from: previous
        )
    }

    func setRoot(destination: R, animated: Bool = true) {
        setRoot(destinations: [destination], animated: animated)
    }
}

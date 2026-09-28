//
//  FidraRoutingProvider.swift
//  FidraRouting
//
//  Created by nguyen anh tuan on 03/08/2025.
//

import SwiftUI

@MainActor
public final class FidraRoutingProvider<R: Routable, DialogType: DialogTypeProtocol, SheetType: SheetTypeProtocol>: @preconcurrency DialogRoutable, @preconcurrency SheetRoutable, ObservableObject {
    @Published public var currentDialog: DialogRoute<DialogType>?
    @Published public var dialogs: [DialogRoute<DialogType>] = []
    public typealias dialogType = DialogType
    @Published public var currentSheet: SheetRoute<SheetType>?
    @Published public var sheets: [SheetRoute<SheetType>] = []
    public typealias sheetType = SheetType
    private var middlewares: [NavigationMiddleware] = []
    var deepLinkDefinitions: [ResolvedDeepLink<R>] = []
    public var dialogMiddlewares: [DialogMiddleware] = []
    public var sheetMiddlewares: [SheetMiddleware] = []
    @Published public var screenStack: [R] = []
    /// Per-tab logical screen stack for middleware (tracking / ads) — independent of SwiftUI `NavigationStack`.
    @Published public var tabStacks: [AnyHashable: [R]] = [:]
    @Published public var currentTab: AnyHashable?
    /// Active tab's root virtual screen (`home`, `art_gallery`, …) — not the global `screenStack`.
    @Published public var embeddedScreenRoute: R?
    var nextScreen: R?

    /// Called when a route with `.intercept` swipe policy receives a swipe-back gesture.
    public var swipeBackInterceptHandler: ((R) -> Void)?

    public init(rootScreen: R) {
        self.screenStack = [rootScreen]
        Task { @MainActor in
            DialogType.registerDialog()
            SheetType.registerSheet()
        }
    }

    public var rootScreen: R {
        screenStack.first!
    }

    public func addMiddleware(_ middleware: NavigationMiddleware) {
        middlewares.append(middleware)
    }

    func executeMiddlewares(
        navigationAction: NavigationAction,
        nextScreen: R? = nil,
        previousScreen: R? = nil,
        completion: @escaping () -> Void
    ) {
        let stackPrevious = screenStack.count >= 2 ? screenStack[screenStack.count - 2] : nil
        let stackCurrent = screenStack.last
        let (previous, current) = resolveMiddlewarePreviousCurrent(
            navigationAction: navigationAction,
            previousScreen: previousScreen,
            stackPrevious: stackPrevious,
            stackCurrent: stackCurrent
        )
        let nextScreenValue = resolveMiddlewareNext(
            navigationAction: navigationAction,
            nextScreen: nextScreen,
            stackPrevious: stackPrevious
        )

        var index = 0
        func next() {
            if index < middlewares.count {
                middlewares[index].execute(
                    previous: previous,
                    current: current,
                    next: nextScreenValue,
                    action: navigationAction
                ) {
                    index += 1
                    next()
                }
            } else {
                completion()
            }
        }
        next()
    }

    func performEmbeddedScreenChange(
        tab: AnyHashable?,
        tabRoot: R,
        nextVisible: R,
        from previous: R?
    ) {
        let currentVisible = visibleScreenRoute(stackCurrent: screenStack.last)
        if currentTab == tab, currentVisible?.screenName == nextVisible.screenName { return }

        executeMiddlewares(
            navigationAction: .embeddedScreenChange,
            nextScreen: nextVisible,
            previousScreen: previous ?? currentVisible
        ) { [weak self] in
            guard let self else { return }
            if let tab { self.currentTab = tab }
            self.embeddedScreenRoute = tabRoot
        }
    }

    /// Top logical screen inside `tab` — tab-local stack top, else tab root.
    func visibleTabScreen(for tab: AnyHashable?, fallback: R?) -> R? {
        guard let tab else { return fallback }
        if let top = tabStacks[tab]?.last { return top }
        return fallback
    }

    /// Clears TabView / embedded state when the global stack is reset (e.g. setRoot after paywall).
    func clearContainerNavigationState() {
        embeddedScreenRoute = nil
        tabStacks = [:]
        currentTab = nil
        nextScreen = nil
    }

    func shouldResetContainerState(for destinations: [R]) -> Bool {
        guard let newRoot = destinations.first else { return false }
        if screenStack.first?.screenName != newRoot.screenName { return true }
        return destinations.count == 1 && isContainerRoute(newRoot)
    }

    /// Logical visible screen for middleware — global overlay > tab stack top > tab root.
    func visibleScreenRoute(stackCurrent: R?) -> R? {
        if screenStack.count > 1 {
            return stackCurrent
        }
        if let root = screenStack.first, isContainerRoute(root) {
            return visibleTabScreen(for: currentTab, fallback: embeddedScreenRoute) ?? root
        }
        return stackCurrent ?? embeddedScreenRoute
    }

    func upcomingTabScreenAfterPop(tab: AnyHashable) -> R? {
        guard let stack = tabStacks[tab], !stack.isEmpty else {
            return embeddedScreenRoute
        }
        if stack.count == 1 {
            return embeddedScreenRoute
        }
        return stack[stack.count - 2]
    }

    private func embeddedWhenReturningToContainerRoot(_ target: R?) -> R? {
        guard let target, let root = screenStack.first else { return target }
        guard isContainerRoute(root), target.screenName == root.screenName else { return target }
        return visibleScreenRoute(stackCurrent: root) ?? root
    }

    private func isContainerRoute(_ route: R) -> Bool {
        presentationStyle(for: route) == .container
    }

    private func resolveMiddlewarePreviousCurrent(
        navigationAction: NavigationAction,
        previousScreen: R?,
        stackPrevious: R?,
        stackCurrent: R?
    ) -> (previous: R?, current: R?) {
        switch navigationAction {
        case .embeddedScreenChange:
            let currentVisible = visibleScreenRoute(stackCurrent: stackCurrent)
            return (previousScreen ?? stackPrevious, currentVisible)
        default:
            return (previousScreen ?? stackPrevious, visibleScreenRoute(stackCurrent: stackCurrent))
        }
    }

    private func resolveMiddlewareNext(
        navigationAction: NavigationAction,
        nextScreen: R?,
        stackPrevious: R?
    ) -> R? {
        switch navigationAction {
        case .push, .replace, .embeddedScreenChange, .deepLink:
            return nextScreen
        case .pop:
            if screenStack.count == 2, let root = screenStack.first, isContainerRoute(root) {
                return visibleScreenRoute(stackCurrent: root) ?? root
            }
            return stackPrevious
        case .popCount, .popTo:
            return embeddedWhenReturningToContainerRoot(nextScreen ?? stackPrevious ?? screenStack.first)
        case .popToRoot:
            return embeddedWhenReturningToContainerRoot(nextScreen ?? screenStack.first)
        }
    }

    var navigationPath: Binding<[R]> {
        Binding(
            get: {
                Array(self.screenStack.dropFirst())
            },
            set: { newPath in
                if let root = self.screenStack.first {
                    self.screenStack = [root] + newPath
                } else {
                    self.screenStack = newPath
                }
            }
        )
    }

    func performNavigation(animated: Bool, _ changes: () -> Void) {
        if animated {
            withAnimation { changes() }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction, changes)
        }
    }

    public func present(handleDeepLinksAutomatically: Bool = true) -> some View {
        FidraRoutingNavigationHost(
            router: self,
            handleDeepLinksAutomatically: handleDeepLinksAutomatically
        )
        .sheetContainer(router: self, presentation: .global)
    }

    var rootPresentationStyle: RoutePresentationStyle {
        guard let root = screenStack.first else { return .stack }
        return presentationStyle(for: root)
    }

    func presentationStyle(for route: R) -> RoutePresentationStyle {
        if let provider = route as? any FidraPresentationStyleProviding {
            return provider.presentationStyle
        }
        return .stack
    }

    /// Stable identity for root view — tránh mount 2 instance khi đổi host stack/container.
    var rootIdentityKey: String {
        screenStack.first?.screenName ?? "fidra-root-empty"
    }

    /// The route currently visible at the top of the stack.
    public var currentRoute: R {
        screenStack.last ?? rootScreen
    }

    /// Handles a swipe-back gesture for `route` according to its `SwipeBackPolicy`.
    public func handleSwipeBack(from route: R) {
        guard isTopRoute(route) else { return }
        guard screenStack.count > 1 else { return }

        let policy = (route as? SwipeBackConfigurable)?.swipeBackPolicy ?? .disabled
        switch policy {
        case .disabled:
            return
        case .pop:
            popFromSwipeBack()
        case .intercept:
            swipeBackInterceptHandler?(route)
        }
    }

    private func isTopRoute(_ route: R) -> Bool {
        screenStack.last == route
    }

    private func popFromSwipeBack() {
        guard screenStack.count > 1 else { return }

        executeMiddlewares(navigationAction: .pop, nextScreen: nil) { [weak self] in
            guard let self else { return }
            self.performNavigation(animated: true) {
                self.screenStack.removeLast()
            }
        }
    }
}

@available(iOS 16, *)
private struct FidraRoutingNavigationHost<
    R: Routable,
    DialogType: DialogTypeProtocol,
    SheetType: SheetTypeProtocol
>: View {
    @ObservedObject var router: FidraRoutingProvider<R, DialogType, SheetType>
    var handleDeepLinksAutomatically: Bool

    var body: some View {
        Group {
            if router.rootPresentationStyle == .container {
                FidraContainerNavigationHost(
                    router: router,
                    handleDeepLinksAutomatically: handleDeepLinksAutomatically
                )
            } else {
                FidraStackNavigationHost(
                    router: router,
                    handleDeepLinksAutomatically: handleDeepLinksAutomatically
                )
            }
        }
        .id(router.rootIdentityKey + "-" + String(describing: router.rootPresentationStyle))
    }
}

@available(iOS 16, *)
private struct FidraStackNavigationHost<
    R: Routable,
    DialogType: DialogTypeProtocol,
    SheetType: SheetTypeProtocol
>: View {
    @ObservedObject var router: FidraRoutingProvider<R, DialogType, SheetType>
    var handleDeepLinksAutomatically: Bool

    var body: some View {
        NavigationStack(path: router.navigationPath) {
            rootContent
                .fidraSwipeBackOverlay(route: router.rootScreen, provider: router)
                .navigationDestination(for: R.self) { route in
                    route
                        .id(route)
                        .fidraSwipeBackOverlay(route: route, provider: router)
                }
        }
        .modifier(DeepLinkOpenURLModifier(
            isEnabled: handleDeepLinksAutomatically,
            handler: { url in
                router.handleDeepLink(url)
            }
        ))
    }

    @ViewBuilder
    private var rootContent: some View {
        if let root = router.screenStack.first {
            root
                .id(router.rootIdentityKey)
        }
    }
}

/// Root container (TabView, v.v.) không bọc `NavigationStack` — push hiển thị overlay stack.
@available(iOS 16, *)
private struct FidraContainerNavigationHost<
    R: Routable,
    DialogType: DialogTypeProtocol,
    SheetType: SheetTypeProtocol
>: View {
    @ObservedObject var router: FidraRoutingProvider<R, DialogType, SheetType>
    var handleDeepLinksAutomatically: Bool

    var body: some View {
        ZStack {
            rootContent

            if router.screenStack.count > 1 {
                NavigationStack(path: router.navigationPath) {
                    FidraNavigationAnchor()
                        .navigationDestination(for: R.self) { route in
                            route
                                .id(route)
                                .fidraSwipeBackOverlay(route: route, provider: router)
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .zIndex(1)
            }
        }
        .modifier(DeepLinkOpenURLModifier(
            isEnabled: handleDeepLinksAutomatically,
            handler: { url in
                router.handleDeepLink(url)
            }
        ))
    }

    @ViewBuilder
    private var rootContent: some View {
        if let root = router.screenStack.first {
            root
                .id(router.rootIdentityKey)
        }
    }
}

@available(iOS 16, *)
private struct FidraNavigationAnchor: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }
}

private struct DeepLinkOpenURLModifier: ViewModifier {
    let isEnabled: Bool
    let handler: (URL) -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content.onOpenURL(perform: handler)
        } else {
            content
        }
    }
}

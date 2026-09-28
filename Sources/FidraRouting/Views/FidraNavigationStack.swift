//
//  FidraNavigationStack.swift
//  FidraRouting
//

import SwiftUI

/// Local `NavigationStack` for TabView tab chrome (toolbar). Không bind router path.
@available(iOS 16, *)
public struct FidraNavigationStack<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        NavigationStack {
            content
        }
    }
}

@available(iOS 16, *)
public extension View {
    /// NavigationStack cục bộ trong tab — dùng với root `.container`, push đi qua overlay của router.
    func fidraNavigationStack() -> some View {
        FidraNavigationStack {
            self
        }
    }
}

extension View {
    func fidraSwipeBackOverlay<
        R: Routable,
        DialogType: DialogTypeProtocol,
        SheetType: SheetTypeProtocol
    >(
        route: R,
        provider: FidraRoutingProvider<R, DialogType, SheetType>
    ) -> some View {
        let policy = (route as? SwipeBackConfigurable)?.swipeBackPolicy ?? .disabled
        return fidraSwipeBackEdge(isEnabled: policy != .disabled) {
            provider.handleSwipeBack(from: route)
        }
    }
}

public extension View {
    func fidraTabNavigationStack<R: Routable, D: DialogTypeProtocol, S: SheetTypeProtocol>(
        router: FidraRoutingProvider<R, D, S>,
        tab: AnyHashable
    ) -> some View {
        let binding = Binding<[R]>(
            get: { router.tabStacks[tab] ?? [] },
            set: { router.tabStacks[tab] = $0 }
        )
        return NavigationStack(path: binding) {
            self.navigationDestination(for: R.self) { route in
                route
                    .id(route)
                    .fidraSwipeBackOverlay(route: route, provider: router)
            }
        }
    }
}

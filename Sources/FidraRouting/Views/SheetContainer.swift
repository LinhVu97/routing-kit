//
//  SheetContainer.swift
//  FidraRouting
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct SheetContainer<Router: SheetRoutable & ObservableObject>: ViewModifier {
    @ObservedObject var router: Router
    private let presentation: SheetPresentationScope
    
    public init(router: Router, presentation: SheetPresentationScope = .global) {
        self.router = router
        self.presentation = presentation
    }
    
    private var scopedSheet: SheetRoute<Router.SheetType>? {
        router.sheets.last { $0.presentationScope == presentation }
    }
    
    public func body(content: Content) -> some View {
        content.sheet(item: scopedSheetBinding) { sheetRoute in
            sheetContent(for: sheetRoute)
                .modifier(SheetPresentationModifier(options: sheetRoute.presentationOptions))
        }
    }
    
    private var scopedSheetBinding: Binding<SheetRoute<Router.SheetType>?> {
        Binding(
            get: { scopedSheet },
            set: { newValue in
                if newValue == nil, let sheet = scopedSheet {
                    router.dismissSheet(sheet)
                }
            }
        )
    }
    
    @ViewBuilder
    private func sheetContent(for sheetRoute: SheetRoute<Router.SheetType>) -> some View {
        if let view = SheetRegistry.shared.view(for: sheetRoute) {
            view
        } else if let customView = sheetRoute.params["view"] as? AnyView {
            customView
        } else {
            EmptyView()
        }
    }
}

private struct SheetPresentationModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let options: SheetPresentationOptions
    
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            styledContent(from: content)
        } else {
            content
                .interactiveDismissDisabled(!options.isInteractiveDismissEnabled)
        }
    }
    
    @ViewBuilder
    private func styledContent(from content: Content) -> some View {
        if let height = options.singleHeightDetent {
            content
                .presentationDragIndicator(options.showsDragIndicator ? .visible : .hidden)
                .presentationDetents([.height(height)])
                .interactiveDismissDisabled(!options.isInteractiveDismissEnabled)
        } else if let presentationDetents = options.presentationDetents {
            content
                .presentationDragIndicator(options.showsDragIndicator ? .visible : .hidden)
                .presentationDetents(presentationDetents)
                .interactiveDismissDisabled(!options.isInteractiveDismissEnabled)
        } else {
            content
                .interactiveDismissDisabled(!options.isInteractiveDismissEnabled)
        }
    }
}

public extension View {
    func sheetContainer<Router: SheetRoutable & ObservableObject>(
        router: Router,
        presentation: SheetPresentationScope = .global
    ) -> some View {
        modifier(SheetContainer(router: router, presentation: presentation))
    }
}

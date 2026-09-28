//
//  DialogContainer.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 8/8/25.
//
import SwiftUI

/// Overlay dialog theo `presentation`: `.global` (mặc định, toàn app) hoặc `.local` (chỉ vùng chứa container, thường đặt trong từng màn).
public struct DialogContainer<Router: DialogRoutable & ObservableObject>: View {

    @ObservedObject var router: Router
    private let presentation: DialogPresentationScope

    /// - Parameters:
    ///   - router: `FidraRoutingProvider` / `DialogManager` khai báo dialog.
    ///   - presentation: `.global` giữ hành vi cũ; `.local` khi đặt container trong màn và show với `presentation: .local`.
    public init(router: Router, presentation: DialogPresentationScope = .global) {
        self.router = router
        self.presentation = presentation
    }

    private var scopedDialogs: [DialogRoute<Router.DialogType>] {
        router.dialogs.filter { $0.presentationScope == presentation }
    }

    public var body: some View {
        ZStack {
            ForEach(scopedDialogs) { dialogRoute in
                if let view = DialogRegistry.shared.view(for: dialogRoute) {
                    view
                        .transition(.opacity)
                } else if let customView = dialogRoute.params["view"] as? AnyView {
                    customView
                        .transition(.opacity)
                }
            }
        }
        .animation(.default, value: scopedDialogs.map(\.id))
    }

}

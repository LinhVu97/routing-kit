//
//  SheetRoute.swift
//  FidraRouting
//

import SwiftUI

public enum SheetPresentationScope: Sendable, Hashable, Equatable {
    case global
    case local
}

public struct SheetRoute<SheetType: SheetTypeProtocol>: Identifiable, Hashable {
    public let id: String
    public let viewId: SheetType
    public let params: [String: Any]
    public let presentationScope: SheetPresentationScope
    public let presentationOptions: SheetPresentationOptions

    var onDismiss: ((Any?) -> Void)?

    init(
        viewId: SheetType,
        params: [String: Any],
        presentationScope: SheetPresentationScope = .global,
        presentationOptions: SheetPresentationOptions = .default,
        onDismiss: ((Any?) -> Void)? = nil
    ) {
        self.id = UUID().uuidString
        self.viewId = viewId
        self.params = params
        self.presentationScope = presentationScope
        self.presentationOptions = presentationOptions
        self.onDismiss = onDismiss
    }

    public func getParams() -> [String: Any] {
        params
    }

    public func getViewId() -> SheetType {
        viewId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(viewId)
        hasher.combine(presentationScope)
        hasher.combine(presentationOptions)
    }

    public static func == (lhs: SheetRoute<SheetType>, rhs: SheetRoute<SheetType>) -> Bool {
        lhs.id == rhs.id
            && lhs.viewId == rhs.viewId
            && lhs.presentationScope == rhs.presentationScope
            && lhs.presentationOptions == rhs.presentationOptions
    }
}

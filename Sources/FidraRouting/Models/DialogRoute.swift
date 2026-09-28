//
//  DialogRoute.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 8/8/25.
//

import SwiftUI

/// Phạm vi hiển thị dialog trên cây view.
/// - `global`: mặc định — overlay ở root, giống hành vi cũ (vẫn thấy khi đổi màn).
/// - `local`: chỉ hiển thị trong `DialogContainer(..., presentation: .local)` đặt trong từng màn; cần gọi `show*(_, presentation: .local)`.
public enum DialogPresentationScope: Sendable, Hashable, Equatable {
    case global
    case local
}

public struct DialogRoute<DialogType: DialogTypeProtocol>: Identifiable, Hashable {
    public let id: String
    public let viewId: DialogType
    public let params: [String: Any]
    public let presentationScope: DialogPresentationScope
    
    /// Continuation callback để hỗ trợ async/await khi dismiss dialog
    var onDismiss: ((Any?) -> Void)?
    
    init(viewId: DialogType, params: [String : Any], presentationScope: DialogPresentationScope = .global, onDismiss: ((Any?) -> Void)? = nil) {
        self.id = UUID().uuidString
        self.viewId = viewId
        self.params = params
        self.presentationScope = presentationScope
        self.onDismiss = onDismiss
    }
    
    public func getParams() -> [String: Any] {
        return params
    }
    
    public func getViewId() -> DialogType {
        return viewId
    }
    
    // Triển khai Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(viewId)
        hasher.combine(presentationScope)
    }
    
    public static func == (lhs: DialogRoute<DialogType>, rhs: DialogRoute<DialogType>) -> Bool {
        return lhs.id == rhs.id && lhs.viewId == rhs.viewId && lhs.presentationScope == rhs.presentationScope
    }
}

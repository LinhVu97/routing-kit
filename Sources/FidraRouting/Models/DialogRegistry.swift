//
//  DialogRegistry.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 8/8/25.
//



import Foundation
import SwiftUI

public final class DialogRegistry: @unchecked Sendable {
    public static let shared = DialogRegistry()
    
    private var dialogBuilder: [String: (Any) -> AnyView] = [:]
    private init() {}
    
    public func register<DialogType: DialogTypeProtocol, V: View>(
        viewId: DialogType,
        builder: @escaping ([String: Any]) -> V
    ) {
        dialogBuilder[viewId.rawValue] = { router in
            guard let dialogRouter = router as? DialogRoute<DialogType> else {
                return AnyView(EmptyView())
            }
            return AnyView(builder(dialogRouter.params))
        }
    }
    
    public func view<DialogType: DialogTypeProtocol>(for route: DialogRoute<DialogType>) -> AnyView? {
        return dialogBuilder[route.viewId.rawValue]?(route)
    }
}

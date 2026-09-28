//
//  SheetRegistry.swift
//  FidraRouting
//

import Foundation
import SwiftUI

public final class SheetRegistry: @unchecked Sendable {
    public static let shared = SheetRegistry()

    private var sheetBuilder: [String: (Any) -> AnyView] = [:]

    private init() {}

    public func register<SheetType: SheetTypeProtocol, V: View>(
        viewId: SheetType,
        builder: @escaping ([String: Any]) -> V
    ) {
        sheetBuilder[viewId.rawValue] = { router in
            guard let sheetRouter = router as? SheetRoute<SheetType> else {
                return AnyView(EmptyView())
            }
            return AnyView(builder(sheetRouter.params))
        }
    }

    public func view<SheetType: SheetTypeProtocol>(for route: SheetRoute<SheetType>) -> AnyView? {
        sheetBuilder[route.viewId.rawValue]?(route)
    }
}

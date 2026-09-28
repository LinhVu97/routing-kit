//
//  SheetManager.swift
//  FidraRouting
//

import Foundation
import SwiftUI

public final class SheetManager<SheetType: SheetTypeProtocol>: SheetRoutable, ObservableObject {
    @Published public var currentSheet: SheetRoute<SheetType>?
    @Published public var sheets: [SheetRoute<SheetType>] = []
    public typealias sheetType = SheetType

    public var sheetMiddlewares: [SheetMiddleware] = []

    public init() {
        Task { @MainActor in
            SheetType.registerSheet()
        }
    }
}

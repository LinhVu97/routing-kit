//
//  SheetMiddleware.swift
//  FidraRouting
//

import Foundation

public protocol SheetMiddleware {
    func execute(sheetId: String, action: SheetAction, completion: @escaping () -> Void)
}

public enum SheetAction {
    case show
    case dismiss
    case dismissAll
}

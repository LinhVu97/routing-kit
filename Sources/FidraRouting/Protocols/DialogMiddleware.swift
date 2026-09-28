//
//  DialogMiddleware.swift
//  FidraRouting
//
//  Created by Auto on 01/08/2025.
//

import Foundation

public protocol DialogMiddleware {
    func execute(dialogId: String, action: DialogAction, completion: @escaping () -> Void)
}

public enum DialogAction {
    case show
    case dismiss
    case dismissAll
}


//
//  NavigationMiddleware.swift
//  FidraRouting
//
//  Created by nguyen anh tuan on 01/08/2025.
//

import Foundation
import SwiftUI

/// Protocol for navigation middleware.
public protocol NavigationMiddleware {
    func execute(previous: Any?, current: Any?, next: Any?, action: NavigationAction, completion: @escaping () -> Void)
}

/// Enum defining navigation actions.
public enum NavigationAction {
    case push
    case pop
    case replace
    case popToRoot
    case popTo
    case popCount
    case deepLink
    /// Logical tab / embedded screen change (TabView) — middleware only, no global `screenStack` mutation.
    case embeddedScreenChange
}

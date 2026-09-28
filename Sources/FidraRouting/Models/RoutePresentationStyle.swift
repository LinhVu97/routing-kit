//
//  RoutePresentationStyle.swift
//  FidraRouting
//

import Foundation

/// Cách host render route.
public enum RoutePresentationStyle: Sendable {
    /// Route nằm trong `NavigationStack` (mặc định).
    case stack
    /// App shell (TabView, v.v.) — không bọc `NavigationStack` ở root; push hiển thị overlay stack.
    case container
}

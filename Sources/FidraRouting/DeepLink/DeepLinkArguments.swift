//
//  DeepLinkArguments.swift
//  FidraRouting
//

import Foundation

public struct DeepLinkArguments: Sendable {
    public let path: [String: String]
    public let query: [String: String]

    public init(path: [String: String] = [:], query: [String: String] = [:]) {
        self.path = path
        self.query = query
    }

    public subscript(_ key: String) -> String? {
        path[key] ?? query[key]
    }
}

//
//  RouteMetadata.swift
//  FidraRouting
//

import Foundation

public protocol RouteGraphPlaceholderSupporting {
    static func makeRouteGraphPlaceholder() -> Any
}

public protocol RouteGraphPlaceholder: RouteGraphPlaceholderSupporting {
    static var routeGraphPlaceholder: Self { get }
}

public extension RouteGraphPlaceholder {
    static func makeRouteGraphPlaceholder() -> Any { routeGraphPlaceholder }
}

public enum RouteMetadata {
    public static func caseName<R>(for route: R) -> String {
        let mirror = Mirror(reflecting: route)
        if mirror.displayStyle == .enum {
            if let label = mirror.children.first?.label {
                return label
            }
        }

        var description = String(describing: route)
        if let dotIndex = description.lastIndex(of: ".") {
            description = String(description[description.index(after: dotIndex)...])
        }
        if let parenthesisIndex = description.firstIndex(of: "(") {
            description = String(description[..<parenthesisIndex])
        }
        return description
    }

    static func firstAssociatedValue<R, Arg>(from route: R, as type: Arg.Type) -> Arg? {
        func find(in value: Any) -> Arg? {
            if let match = value as? Arg {
                return match
            }
            for child in Mirror(reflecting: value).children {
                if let match = find(in: child.value) {
                    return match
                }
            }
            return nil
        }
        return find(in: route)
    }

    static func placeholder<Arg>(for type: Arg.Type) -> Arg {
        switch type {
        case is String.Type:
            return "" as! Arg
        case is Int.Type:
            return 0 as! Arg
        case is Bool.Type:
            return false as! Arg
        default:
            if let placeholderType = type as? RouteGraphPlaceholderSupporting.Type {
                return placeholderType.makeRouteGraphPlaceholder() as! Arg
            }
            fatalError("Unsupported route argument type: \(type). Conform to RouteGraphPlaceholder or pass an explicit `screenName:` to `route(...)`.")
        }
    }
}

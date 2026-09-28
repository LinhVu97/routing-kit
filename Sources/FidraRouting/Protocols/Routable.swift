//
//  RoutableObject.swift
//  FidraRouting
//
//  Created by nguyen anh tuan on 01/08/2025.
//

import Foundation
import SwiftUI

/// defining a routable view with a screen name.
public typealias Routable = View & Hashable & TrackingScreenName

public protocol TrackingScreenName {
    var screenName: String { get }
}

public extension TrackingScreenName where Self: Hashable {
    var screenName: String {
        RouteMetadata.caseName(for: self)
    }
}

public protocol FidraPresentationStyleProviding: Routable {
    var presentationStyle: RoutePresentationStyle { get }
}

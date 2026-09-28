//
//  Transition+Ext.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 8/8/25.
//
import SwiftUI

public extension AnyTransition {
     static var moveAndOpacity: AnyTransition {
        return .move(edge: .leading).combined(with: .opacity)
    }
}

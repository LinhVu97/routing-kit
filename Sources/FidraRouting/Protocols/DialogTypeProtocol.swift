//
//  DialogTypeProtocol.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 8/8/25.
//

import Foundation


public protocol DialogTypeProtocol: RawRepresentable, Hashable where RawValue == String {
    
    @MainActor
    static func registerDialog()
}

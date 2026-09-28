//
//  SheetTypeProtocol.swift
//  FidraRouting
//

import Foundation

public protocol SheetTypeProtocol: RawRepresentable, Hashable where RawValue == String {
    @MainActor
    static func registerSheet()
}

public enum DefaultSheetType: String, SheetTypeProtocol {
    case custom

    @MainActor
    public static func registerSheet() {}
}

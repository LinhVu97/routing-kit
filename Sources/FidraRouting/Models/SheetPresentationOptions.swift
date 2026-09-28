//
//  SheetPresentationOptions.swift
//  FidraRouting
//

import SwiftUI

public enum SheetDetent: Sendable, Hashable {
    case medium
    case large
    case fraction(Double)
    case height(Double)
}

public struct SheetPresentationOptions: Sendable, Hashable {
    public var showsDragIndicator: Bool
    public var isInteractiveDismissEnabled: Bool
    /// `nil` giữ presentation mặc định của hệ thống (iPad: form sheet căn giữa).
    public var detents: [SheetDetent]?

    public init(
        showsDragIndicator: Bool = true,
        isInteractiveDismissEnabled: Bool = true,
        detents: [SheetDetent]? = nil
    ) {
        self.showsDragIndicator = showsDragIndicator
        self.isInteractiveDismissEnabled = isInteractiveDismissEnabled
        self.detents = detents?.isEmpty == true ? nil : detents
    }

    /// Hành vi giống `.sheet()` mặc định của SwiftUI.
    public static let `default` = SheetPresentationOptions()

    /// Bottom sheet kiểu iPhone với detents `.medium` / `.large`.
    public static let bottomSheet = SheetPresentationOptions(
        detents: [.medium, .large]
    )

    public static func fixedHeight(
        _ height: Double,
        showsDragIndicator: Bool = true,
        isInteractiveDismissEnabled: Bool = true
    ) -> SheetPresentationOptions {
        SheetPresentationOptions(
            showsDragIndicator: showsDragIndicator,
            isInteractiveDismissEnabled: isInteractiveDismissEnabled,
            detents: [.height(height)]
        )
    }

    public static func fraction(
        _ value: Double,
        showsDragIndicator: Bool = true,
        isInteractiveDismissEnabled: Bool = true
    ) -> SheetPresentationOptions {
        SheetPresentationOptions(
            showsDragIndicator: showsDragIndicator,
            isInteractiveDismissEnabled: isInteractiveDismissEnabled,
            detents: [.fraction(value)]
        )
    }
}

@available(iOS 16.0, *)
extension SheetDetent {
    var presentationDetent: PresentationDetent {
        switch self {
        case .medium:
            return .medium
        case .large:
            return .large
        case .fraction(let value):
            return .fraction(value)
        case .height(let value):
            return .height(value)
        }
    }
}

extension SheetPresentationOptions {
    var singleHeightDetent: Double? {
        guard let detents, detents.count == 1 else { return nil }
        if case .height(let height) = detents[0] {
            return height
        }
        return nil
    }
}

@available(iOS 16.0, *)
extension SheetPresentationOptions {
    var presentationDetents: Set<PresentationDetent>? {
        guard singleHeightDetent == nil, let detents else { return nil }
        return Set(detents.map(\.presentationDetent))
    }
}

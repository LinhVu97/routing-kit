//
//  SheetRoutable.swift
//  FidraRouting
//

import Foundation
import SwiftUI

public protocol SheetRoutable: AnyObject {
    associatedtype SheetType: SheetTypeProtocol

    @MainActor
    var currentSheet: SheetRoute<SheetType>? { get set }

    @MainActor
    var sheets: [SheetRoute<SheetType>] { get set }

    var sheetMiddlewares: [SheetMiddleware] { get set }

    @MainActor
    func showSheet(
        viewId: SheetType,
        params: [String: Any],
        presentation: SheetPresentationScope,
        options: SheetPresentationOptions
    )

    @MainActor
    func dismissSheet()

    @MainActor
    func dismissSheet(viewId: SheetType)

    @MainActor
    func dismissSheet(_ sheet: SheetRoute<SheetType>)

    @MainActor
    func dismissAllSheets()

    @MainActor
    func showSheetView<V: View>(
        _ view: V,
        viewId: SheetType,
        presentation: SheetPresentationScope,
        options: SheetPresentationOptions
    )

    @MainActor
    func showSheet<V: View>(_ view: V, presentation: SheetPresentationScope, options: SheetPresentationOptions)

    @MainActor
    func showSheetViewAsync<V: View, T>(
        _ view: V,
        viewId: SheetType,
        resultType: T.Type,
        presentation: SheetPresentationScope,
        options: SheetPresentationOptions
    ) async -> T?

    @MainActor
    func showSheetViewAsync<V: View>(
        _ view: V,
        viewId: SheetType,
        presentation: SheetPresentationScope,
        options: SheetPresentationOptions
    ) async

    @MainActor
    func showSheetAsync<V: View, T>(
        _ view: V,
        resultType: T.Type,
        presentation: SheetPresentationScope,
        options: SheetPresentationOptions
    ) async -> T?

    @MainActor
    func showSheetAsync<V: View>(
        _ view: V,
        presentation: SheetPresentationScope,
        options: SheetPresentationOptions
    ) async

    @MainActor
    func dismissSheetWithResult(_ result: Any?)

    func addSheetMiddleware(_ middleware: SheetMiddleware)

    func addSheetMiddlewares(_ middlewares: [SheetMiddleware])
}

public extension SheetRoutable {
    func addSheetMiddleware(_ middleware: SheetMiddleware) {
        sheetMiddlewares.append(middleware)
    }

    func addSheetMiddlewares(_ middlewares: [SheetMiddleware]) {
        sheetMiddlewares.append(contentsOf: middlewares)
    }

    func executeSheetMiddlewares(sheetId: String, action: SheetAction, completion: @escaping () -> Void) {
        guard !sheetMiddlewares.isEmpty else {
            completion()
            return
        }

        var index = 0
        func executeNext() {
            guard index < sheetMiddlewares.count else {
                completion()
                return
            }
            let middleware = sheetMiddlewares[index]
            index += 1
            middleware.execute(sheetId: sheetId, action: action) {
                executeNext()
            }
        }
        executeNext()
    }

    @MainActor
    func dismissSheet() {
        guard let topSheet = sheets.last else { return }
        dismissSheet(topSheet)
    }

    @MainActor
    func dismissSheet(viewId: SheetType) {
        guard let targetSheet = sheets.last(where: { $0.viewId == viewId }) else { return }
        dismissSheet(targetSheet)
    }

    @MainActor
    func dismissSheetWithResult(_ result: Any?) {
        let sheetId = currentSheet?.viewId.rawValue ?? ""
        let onDismiss = currentSheet?.onDismiss
        if !sheets.isEmpty {
            sheets.removeLast()
        }
        currentSheet = sheets.last

        onDismiss?(result)
        executeSheetMiddlewares(sheetId: sheetId, action: .dismiss) { }
    }

    @MainActor
    func dismissSheet(_ sheet: SheetRoute<SheetType>) {
        let targetSheet = sheets.first { $0.id == sheet.id }
        let onDismiss = targetSheet?.onDismiss

        sheets.removeAll { $0.id == sheet.id }
        currentSheet = sheets.last

        onDismiss?(nil)
        executeSheetMiddlewares(sheetId: sheet.viewId.rawValue, action: .dismiss) { }
    }

    @MainActor
    func dismissAllSheets() {
        let sheetId = currentSheet?.viewId.rawValue ?? ""

        for sheet in sheets {
            sheet.onDismiss?(nil)
        }

        currentSheet = nil
        sheets.removeAll()

        executeSheetMiddlewares(sheetId: sheetId, action: .dismissAll) { }
    }

    @MainActor
    func showSheet(
        viewId: SheetType,
        params: [String: Any] = [:],
        presentation: SheetPresentationScope = .global,
        options: SheetPresentationOptions = .default
    ) {
        let sheet = SheetRoute(
            viewId: viewId,
            params: params,
            presentationScope: presentation,
            presentationOptions: options
        )
        currentSheet = sheet
        sheets.append(sheet)
        executeSheetMiddlewares(sheetId: viewId.rawValue, action: .show) { }
    }

    @MainActor
    func showSheetView<V: View>(
        _ view: V,
        viewId: SheetType,
        presentation: SheetPresentationScope = .global,
        options: SheetPresentationOptions = .default
    ) {
        let sheet = SheetRoute(
            viewId: viewId,
            params: ["view": AnyView(view)],
            presentationScope: presentation,
            presentationOptions: options
        )
        currentSheet = sheet
        sheets.append(sheet)
        executeSheetMiddlewares(sheetId: viewId.rawValue, action: .show) { }
    }

    @MainActor
    func showSheet<V: View>(
        _ view: V,
        presentation: SheetPresentationScope = .global,
        options: SheetPresentationOptions = .default
    ) {
        guard let customType = SheetType(rawValue: "custom") else { return }
        showSheetView(view, viewId: customType, presentation: presentation, options: options)
    }

    @MainActor
    func showSheetViewAsync<V: View, T>(
        _ view: V,
        viewId: SheetType,
        resultType: T.Type,
        presentation: SheetPresentationScope = .global,
        options: SheetPresentationOptions = .default
    ) async -> T? {
        await withCheckedContinuation { continuation in
            let sheet = SheetRoute(
                viewId: viewId,
                params: ["view": AnyView(view)],
                presentationScope: presentation,
                presentationOptions: options,
                onDismiss: { @Sendable result in
                    nonisolated(unsafe) let value = result as? T
                    continuation.resume(returning: value)
                }
            )
            currentSheet = sheet
            sheets.append(sheet)
            executeSheetMiddlewares(sheetId: viewId.rawValue, action: .show) { }
        }
    }

    @MainActor
    func showSheetViewAsync<V: View>(
        _ view: V,
        viewId: SheetType,
        presentation: SheetPresentationScope = .global,
        options: SheetPresentationOptions = .default
    ) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let sheet = SheetRoute(
                viewId: viewId,
                params: ["view": AnyView(view)],
                presentationScope: presentation,
                presentationOptions: options,
                onDismiss: { _ in
                    continuation.resume()
                }
            )
            currentSheet = sheet
            sheets.append(sheet)
            executeSheetMiddlewares(sheetId: viewId.rawValue, action: .show) { }
        }
    }

    @MainActor
    func showSheetAsync<V: View, T>(
        _ view: V,
        resultType: T.Type,
        presentation: SheetPresentationScope = .global,
        options: SheetPresentationOptions = .default
    ) async -> T? {
        guard let customType = SheetType(rawValue: "custom") else { return nil }
        return await showSheetViewAsync(
            view,
            viewId: customType,
            resultType: resultType,
            presentation: presentation,
            options: options
        )
    }

    @MainActor
    func showSheetAsync<V: View>(
        _ view: V,
        presentation: SheetPresentationScope = .global,
        options: SheetPresentationOptions = .default
    ) async {
        guard let customType = SheetType(rawValue: "custom") else { return }
        await showSheetViewAsync(view, viewId: customType, presentation: presentation, options: options)
    }
}

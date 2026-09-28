//
//  DialogRoutable.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 8/8/25.
//
import Foundation
import SwiftUI

public protocol DialogRoutable: AnyObject {
    
    associatedtype  DialogType: DialogTypeProtocol
    
    @MainActor
    var currentDialog: DialogRoute<DialogType>? { get set }
    
    @MainActor
    var dialogs: [DialogRoute<DialogType>] { get set }
    
    var dialogMiddlewares: [DialogMiddleware] { get set }
    
//    @MainActor
//    var transition: AnyTransition? { get set }
    
    @MainActor
    func showDialog(viewId: DialogType, params: [String: Any], presentation: DialogPresentationScope)
    
    @MainActor
    func dismissDialog()
    
    @MainActor
    func dismissDialog(viewId: DialogType)
    
    @MainActor
    func dismissDialog(_ dialog: DialogRoute<DialogType>)
    
    @MainActor
    func dismissAllDialogs()
    
    /// Hiển thị dialog với view được truyền vào
    /// - Parameter view: View cần hiển thị dưới dạng dialog
    @MainActor
    func showDialogView<V: View>(_ view: V, viewId: DialogType, presentation: DialogPresentationScope)
    
    /// Hiển thị dialog với view được truyền vào
    /// - Parameter view: View cần hiển thị dưới dạng dialog
    @MainActor
    func showDialog<V: View>(_ view: V, presentation: DialogPresentationScope)
    
    /// Hiển thị dialog với view và await cho đến khi dialog được dismiss
    /// Giống như Get.dialog() trong GetX Flutter
    /// - Parameters:
    ///   - view: View cần hiển thị dưới dạng dialog
    ///   - viewId: ID của dialog type
    ///   - resultType: Type của kết quả trả về (ví dụ: String.self, Bool.self)
    /// - Returns: Kết quả trả về khi dialog dismiss (có thể là nil)
    @MainActor
    func showDialogViewAsync<V: View, T>(_ view: V, viewId: DialogType, resultType: T.Type, presentation: DialogPresentationScope) async -> T?
    
    /// Hiển thị dialog với view và await cho đến khi dialog được dismiss (không cần kết quả)
    /// - Parameters:
    ///   - view: View cần hiển thị dưới dạng dialog
    ///   - viewId: ID của dialog type
    @MainActor
    func showDialogViewAsync<V: View>(_ view: V, viewId: DialogType, presentation: DialogPresentationScope) async
    
    /// Hiển thị dialog với view và await cho đến khi dialog được dismiss (sử dụng viewId mặc định là "custom")
    /// - Parameters:
    ///   - view: View cần hiển thị dưới dạng dialog
    ///   - resultType: Type của kết quả trả về (ví dụ: String.self, Bool.self)
    /// - Returns: Kết quả trả về khi dialog dismiss (có thể là nil)
    @MainActor
    func showDialogAsync<V: View, T>(_ view: V, resultType: T.Type, presentation: DialogPresentationScope) async -> T?
    
    /// Hiển thị dialog với view và await cho đến khi dialog được dismiss (không cần kết quả)
    /// - Parameter view: View cần hiển thị dưới dạng dialog
    @MainActor
    func showDialogAsync<V: View>(_ view: V, presentation: DialogPresentationScope) async
    
    /// Dismiss dialog hiện tại và trả về kết quả cho caller đang await
    /// - Parameter result: Kết quả trả về cho caller
    @MainActor
    func dismissDialogWithResult(_ result: Any?)
    
    /// Adds a dialog middleware.
    /// - Parameter middleware: The dialog middleware to add.
    func addDialogMiddleware(_ middleware: DialogMiddleware)
    
    /// Adds multiple dialog middlewares.
    /// - Parameter middlewares: The dialog middlewares to add.
    func addDialogMiddlewares(_ middlewares: [DialogMiddleware])
}


public extension DialogRoutable {
    
    func addDialogMiddleware(_ middleware: DialogMiddleware) {
        dialogMiddlewares.append(middleware)
    }
    
    func addDialogMiddlewares(_ middlewares: [DialogMiddleware]) {
        dialogMiddlewares.append(contentsOf: middlewares)
    }
    
    func executeDialogMiddlewares(dialogId: String, action: DialogAction, completion: @escaping () -> Void) {
        guard !dialogMiddlewares.isEmpty else {
            completion()
            return
        }
        
        var index = 0
        func executeNext() {
            guard index < dialogMiddlewares.count else {
                completion()
                return
            }
            let middleware = dialogMiddlewares[index]
            index += 1
            middleware.execute(dialogId: dialogId, action: action) {
                executeNext()
            }
        }
        executeNext()
    }
    
    @MainActor
    func dismissDialog() {
        let dialogId = currentDialog?.viewId.rawValue ?? ""
        let onDismiss = currentDialog?.onDismiss
        if !self.dialogs.isEmpty {
            self.dialogs.removeLast()
        }
        self.currentDialog = self.dialogs.last

        // Resume continuation với nil result
        onDismiss?(nil)

        // Execute middlewares AFTER dismissing dialog
        executeDialogMiddlewares(dialogId: dialogId, action: .dismiss) { }
    }

    @MainActor
    func dismissDialog(viewId: DialogType) {
        guard let targetDialog = dialogs.last(where: { $0.viewId == viewId }) else { return }
        dismissDialog(targetDialog)
    }

    @MainActor
    func dismissDialogWithResult(_ result: Any?) {
        let dialogId = currentDialog?.viewId.rawValue ?? ""
        let onDismiss = currentDialog?.onDismiss
        if !self.dialogs.isEmpty {
            self.dialogs.removeLast()
        }
        self.currentDialog = self.dialogs.last

        // Resume continuation với result
        onDismiss?(result)

        // Execute middlewares AFTER dismissing dialog
        executeDialogMiddlewares(dialogId: dialogId, action: .dismiss) { }
    }

    @MainActor
    func dismissDialog(_ dialog: DialogRoute<DialogType>) {
        let targetDialog = self.dialogs.first { $0.id == dialog.id }
        let onDismiss = targetDialog?.onDismiss

        self.dialogs.removeAll { $0.id == dialog.id }
        self.currentDialog = self.dialogs.last

        // Resume continuation với nil result
        onDismiss?(nil)

        // Execute middlewares AFTER dismissing dialog
        executeDialogMiddlewares(dialogId: dialog.viewId.rawValue, action: .dismiss) { }
    }
    
    @MainActor
    func dismissAllDialogs() {
        let dialogId = currentDialog?.viewId.rawValue ?? ""
        
        // Resume tất cả continuations với nil result
        for dialog in dialogs {
            dialog.onDismiss?(nil)
        }
        
        self.currentDialog = nil
        self.dialogs.removeAll()
        
        // Execute middlewares AFTER dismissing all dialogs
        executeDialogMiddlewares(dialogId: dialogId, action: .dismissAll) { }
    }
    
    @MainActor
    func showDialog(viewId: DialogType, params: [String: Any] = [:], presentation: DialogPresentationScope = .global) {
        let dialog = DialogRoute(viewId: viewId, params: params, presentationScope: presentation)
        self.currentDialog = dialog
        self.dialogs.append(dialog)

        // Execute middlewares AFTER showing dialog
        executeDialogMiddlewares(dialogId: viewId.rawValue, action: .show) { }
    }

    @MainActor
    func showDialogView<V: View>(_ view: V, viewId: DialogType, presentation: DialogPresentationScope = .global) {
        let dialog = DialogRoute(viewId: viewId, params: ["view": AnyView(view)], presentationScope: presentation)
        self.currentDialog = dialog
        self.dialogs.append(dialog)

        // Execute middlewares AFTER showing dialog
        executeDialogMiddlewares(dialogId: viewId.rawValue, action: .show) { }
    }

    @MainActor
    func showDialog<V: View>(_ view: V, presentation: DialogPresentationScope = .global) {
        guard let customType = DialogType(rawValue: "custom") else { return }
        showDialogView(view, viewId: customType, presentation: presentation)
    }
    
    /// Hiển thị dialog với view và await cho đến khi dialog được dismiss (có trả về kết quả)
    /// Sử dụng giống như Get.dialog() trong GetX Flutter
    /// - Parameters:
    ///   - view: View cần hiển thị dưới dạng dialog
    ///   - viewId: ID của dialog type
    ///   - resultType: Type của kết quả trả về (ví dụ: String.self, Bool.self)
    /// - Returns: Kết quả trả về khi dialog dismiss (có thể là nil)
    @MainActor
    func showDialogViewAsync<V: View, T>(_ view: V, viewId: DialogType, resultType: T.Type, presentation: DialogPresentationScope = .global) async -> T? {
        return await withCheckedContinuation { continuation in
            let dialog = DialogRoute(
                viewId: viewId,
                params: ["view": AnyView(view)],
                presentationScope: presentation,
                onDismiss: { @Sendable result in
                    nonisolated(unsafe) let value = result as? T
                    continuation.resume(returning: value)
                }
            )
            self.currentDialog = dialog
            self.dialogs.append(dialog)

            executeDialogMiddlewares(dialogId: viewId.rawValue, action: .show) { }
        }
    }

    /// Hiển thị dialog với view và await cho đến khi dialog được dismiss (không cần kết quả)
    /// - Parameters:
    ///   - view: View cần hiển thị dưới dạng dialog
    ///   - viewId: ID của dialog type
    @MainActor
    func showDialogViewAsync<V: View>(_ view: V, viewId: DialogType, presentation: DialogPresentationScope = .global) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let dialog = DialogRoute(
                viewId: viewId,
                params: ["view": AnyView(view)],
                presentationScope: presentation,
                onDismiss: { _ in
                    continuation.resume()
                }
            )
            self.currentDialog = dialog
            self.dialogs.append(dialog)

            // Execute middlewares AFTER showing dialog
            executeDialogMiddlewares(dialogId: viewId.rawValue, action: .show) { }
        }
    }

    /// Hiển thị dialog với view và await cho đến khi dialog được dismiss (có trả về kết quả, sử dụng viewId mặc định là "custom")
    /// - Parameters:
    ///   - view: View cần hiển thị dưới dạng dialog
    ///   - resultType: Type của kết quả trả về (ví dụ: String.self, Bool.self)
    /// - Returns: Kết quả trả về khi dialog dismiss (có thể là nil)
    @MainActor
    func showDialogAsync<V: View, T>(_ view: V, resultType: T.Type, presentation: DialogPresentationScope = .global) async -> T? {
        guard let customType = DialogType(rawValue: "custom") else { return nil }
        return await showDialogViewAsync(view, viewId: customType, resultType: resultType, presentation: presentation)
    }

    /// Hiển thị dialog với view và await cho đến khi dialog được dismiss (không cần kết quả, sử dụng viewId mặc định là "custom")
    /// - Parameter view: View cần hiển thị dưới dạng dialog
    @MainActor
    func showDialogAsync<V: View>(_ view: V, presentation: DialogPresentationScope = .global) async {
        guard let customType = DialogType(rawValue: "custom") else { return }
        await showDialogViewAsync(view, viewId: customType, presentation: presentation)
    }
}

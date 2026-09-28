//
//  DialogManager.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 8/8/25.
//

import Foundation
import SwiftUI

public final class DialogManager<DialogType: DialogTypeProtocol>: DialogRoutable, ObservableObject {
    
    @Published public var currentDialog: DialogRoute<DialogType>?
    @Published public var dialogs: [DialogRoute<DialogType>] = []
    public typealias dialogType = DialogType
    
    public var dialogMiddlewares: [DialogMiddleware] = []
    
    public init() {
        Task { @MainActor in
            DialogType.registerDialog()
        }
    }
}

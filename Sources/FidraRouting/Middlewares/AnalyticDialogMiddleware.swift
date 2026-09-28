//
//  AnalyticDialogMiddleware.swift
//  FidraRouting
//
//  Created by Auto on 01/08/2025.
//

import Foundation

public class AnalyticDialogMiddleware: DialogMiddleware {
    
    private var enabledLogEvent: Bool = false
    private var cbLogEventDialog: (String, DialogAction) -> Void
    
    public init(enabledLogEvent: Bool = false, cbLogEventDialog: @escaping (String, DialogAction) -> Void) {
        self.enabledLogEvent = enabledLogEvent
        self.cbLogEventDialog = cbLogEventDialog
    }
    
    public func execute(dialogId: String, action: DialogAction, completion: @escaping () -> Void) {
        if !self.enabledLogEvent {
            completion()
            return
        }
        self.cbLogEventDialog(dialogId, action)
        completion()
    }
}


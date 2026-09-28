//
//  AnalyticScreenMiddleware.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 4/8/25.
//

import SwiftUI
import Foundation


public class AnalyticScreenMiddleware: NavigationMiddleware {
    
    private var enabledLogEvent: Bool = false
    private var cbLogEventScreen: (String, String, String, NavigationAction) -> Void

    public init(
        enabledLogEvent: Bool = false,
        cbLogEventScreen: @escaping (String, String, String, NavigationAction) -> Void
    ) {
        self.enabledLogEvent = enabledLogEvent
        self.cbLogEventScreen = cbLogEventScreen
    }

    public func execute(previous: Any?, current: Any?, next: Any?, action: NavigationAction, completion: @escaping () -> Void) {
        if !self.enabledLogEvent {
            completion()
            return
        }
        let previousName = (previous as? TrackingScreenName)?.screenName ?? "none"
        let currentName = (current as? TrackingScreenName)?.screenName ?? "none"
        let nextName = (next as? TrackingScreenName)?.screenName ?? "none"
        self.cbLogEventScreen(previousName, currentName, nextName, action)
        completion()
    }
}

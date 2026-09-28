//
//  NavigationMiddlewareObj.swift
//  FidraRouting
//
//  Created by Nguyen anh tuan on 1/8/25.
//

import Foundation

public class AdsInterstitialMiddleware: NavigationMiddleware {
    
    private var isShowAd: (String, String, String) -> Bool
    private var cbShowAd: ((_ completion: @escaping () -> Void ) -> Void)?
    
    public init(isShowAd: @escaping (String, String, String) -> Bool, cbShowAd:  ((_ completion: @escaping () -> Void ) -> Void)? = nil ) {
        self.isShowAd = isShowAd
        self.cbShowAd = cbShowAd
    }
    
    public func execute(previous: Any?, current: Any?, next: Any?, action: NavigationAction, completion: @escaping () -> Void) {
        let previousName = (previous as? TrackingScreenName)?.screenName ?? "none"
        let currentName = (current as? TrackingScreenName)?.screenName ?? "none"
        let nextName = (next as? TrackingScreenName)?.screenName ?? "none"

        // Always unblock navigation first — interstitial shows after stack / embedded state updates.
        completion()

        guard isShowAd(previousName, currentName, nextName), let cbShowAd else { return }
        cbShowAd {}
    }
    
}

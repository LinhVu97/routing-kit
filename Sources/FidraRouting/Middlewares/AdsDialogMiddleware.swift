//
//  AdsDialogMiddleware.swift
//  FidraRouting
//
//  Created by Auto on 01/08/2025.
//

import Foundation

public class AdsDialogMiddleware: DialogMiddleware {
    
    private var isShowAd: (String, DialogAction) -> Bool
    private var cbShowAd: ((_ completion: @escaping () -> Void) -> Void)?
    
    public init(isShowAd: @escaping (String, DialogAction) -> Bool, cbShowAd: ((_ completion: @escaping () -> Void) -> Void)? = nil) {
        self.isShowAd = isShowAd
        self.cbShowAd = cbShowAd
    }
    
    public func execute(dialogId: String, action: DialogAction, completion: @escaping () -> Void) {
        if !self.isShowAd(dialogId, action) {
            completion()
            return
        }
        
        guard cbShowAd != nil else {
            completion()
            return
        }
        cbShowAd!(completion)
    }
}


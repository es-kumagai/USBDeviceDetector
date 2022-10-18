//
//  File.swift
//  
//  
//  Created by Tomohiro Kumagai on 2022/10/18
//  
//

#if os(iOS)
import Foundation

extension USBDeviceDetector {
    
    public override convenience init() {
        
        self.init(notificationCenter: NotificationCenter.default)
    }
}
#endif

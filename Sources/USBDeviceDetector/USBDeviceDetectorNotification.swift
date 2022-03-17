//
//  File.swift
//  
//
//  Created by Tomohiro Kumagai on 2022/03/17.
//

import Ocean

extension USBDeviceDetector {
    
    public struct CurrentDevicesDetectedNotification: NotificationProtocol {
        
        public var detector: USBDeviceDetector
        public var devices: USBDevices
    }
    
    public struct DevicesDidAddNotification: NotificationProtocol {
        
        public var detector: USBDeviceDetector
        public var devices: USBDevices
    }
    
    public struct DevicesDidRemoveNotification: NotificationProtocol {
        
        public var detector: USBDeviceDetector
        public var devices: USBDevices
    }
}

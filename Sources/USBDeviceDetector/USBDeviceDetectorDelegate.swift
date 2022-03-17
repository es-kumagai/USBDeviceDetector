//
//  USBDeviceDetectorDelegate.swift
//  USBDeviceDetector
//
//  Created by Tomohiro Kumagai on 2021/11/14.
//

import Foundation

@objc public protocol USBDeviceDetectorDelegate : NSObjectProtocol {

    @objc optional func usbDeviceDetector(_ detector: USBDeviceDetector, currentDevicesDetected devices: USBDevices)
    
    @objc optional func usbDeviceDetector(_ detector: USBDeviceDetector, devicesDidAdd devices: USBDevices)
    
    @objc optional func usbDeviceDetector(_ detector: USBDeviceDetector, devicesDidRemove devices: USBDevices)
}

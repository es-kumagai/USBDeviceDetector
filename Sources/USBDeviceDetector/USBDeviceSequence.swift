//
//  USBDeviceSequence.swift
//  USBDeviceDetector
//
//  Created by Tomohiro Kumagai on 2021/11/14.
//

import IOKit

public struct USBDeviceSequence : Sequence {
    
    private let rawIterator: IOIterator
    
    init(rawIterator: IOIterator) {
        
        self.rawIterator = rawIterator
    }
    
    public func makeIterator() -> AnyIterator<USBDevice> {
        
        AnyIterator {
            
            rawIterator.next().map(USBDevice.init)
        }
    }
    
    public var devices: [USBDevice] {
        
        Array(self)
    }
}

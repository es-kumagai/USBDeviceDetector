//
//  USBDeviceDetector.swift
//  USBDeviceDetector
//
//  Created by Tomohiro Kumagai on 2021/11/14.
//

import Foundation
import IOKit
import IOKit.usb

public final class USBDeviceDetector : NSObject {
    
    public weak var delegate: USBDeviceDetectorDelegate?
    
    private var notificationPort: IONotificationPortRef
    private var notificationPortRunLoop: CFRunLoopSource
    private var notificationPortIterators: [(IOIterator, selector: Selector)]

    private let matchesUSBDevice = IOServiceMatching(kIOUSBDeviceClassName)
    private var notificationHandlers = [NotificationHandler]()
    
    public override init() {
        
        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        notificationPortRunLoop = IONotificationPortGetRunLoopSource(notificationPort).takeRetainedValue()
        
        notificationPortIterators = [
            (IOIterator(type: kIOPublishNotification), #selector(USBDeviceDetectorDelegate.usbDeviceDetector(_:devicesDidAdd:))),
            (IOIterator(type: kIOTerminatedNotification), #selector(USBDeviceDetectorDelegate.usbDeviceDetector(_:devicesDidRemove:))),
        ]

        super.init()

        CFRunLoopAddSource(CFRunLoopGetCurrent(), notificationPortRunLoop, .defaultMode)

        for (iterator, selector) in notificationPortIterators {
            
            try! addNotification(iterator) { [unowned self] in
                
                let devices = USBDeviceSequence(rawIterator: $0).devices
                
                delegate?.perform(selector, with: self, with: devices)
            }
        }
    }
    
    deinit {
        
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notificationPortRunLoop, .defaultMode)
        IONotificationPortDestroy(notificationPort)
        
        notificationHandlers.removeAll()
    }
}

private class NotificationHandler {

    typealias Callback = (_ iterator: IOIterator) -> Void
    
    private let type: String
    private let callback: Callback
    
    init(type: String, callback: @escaping Callback) {
        
        self.type = type
        self.callback = callback
    }
    
    func invoke(_ iterator: io_iterator_t) {
        
        callback(IOIterator(type: type, iterator: iterator))
    }
    
    func toOpaque() -> UnsafeMutableRawPointer {
        
        Unmanaged.passUnretained(self).toOpaque()
    }
    
    static func from(_ pointer: UnsafeRawPointer) -> NotificationHandler {
        
        Unmanaged.fromOpaque(pointer).takeUnretainedValue()
    }
}

private extension USBDeviceDetector {
    
    func addNotification(_ iterator: IOIterator, callback: @escaping NotificationHandler.Callback) throws {

        let handler = NotificationHandler(type: iterator.type, callback: callback)
        let rawCallback: IOServiceMatchingCallback = { pointer, iterator in

            let callback = NotificationHandler.from(pointer!)
            
            callback.invoke(iterator)
        }
        
        notificationHandlers.append(handler)
        
        guard case KERN_SUCCESS = IOServiceAddMatchingNotification(notificationPort, iterator.type, matchesUSBDevice, rawCallback, handler.toOpaque(), iterator.rawIterator) else {
            
            throw USBDeviceDetector.InstantiationError.failedToAddMatchingNotification(iterator)
        }
        
        let devices = USBDeviceSequence(rawIterator: iterator).devices

        delegate?.usbDeviceDetector?(self, currentDevicesDetected: devices)
    }
}

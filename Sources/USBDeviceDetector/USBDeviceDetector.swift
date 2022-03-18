//
//  USBDeviceDetector.swift
//  USBDeviceDetector
//
//  Created by Tomohiro Kumagai on 2021/11/14.
//

import Foundation
import IOKit
import IOKit.usb
import Ocean

public final class USBDeviceDetector : NSObject {
    
    @IBOutlet public weak var delegate: USBDeviceDetectorDelegate?
    
    private var notificationPort: IONotificationPortRef
    private var notificationPortRunLoop: CFRunLoopSource

    private let matchesUSBDevice = IOServiceMatching(kIOUSBDeviceClassName)
    private var notificationHandlers = [NotificationHandler]()
    private var observingNotificationPorts: [ObservingNotificationPort]
    
    public override init() {
        
        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        notificationPortRunLoop = IONotificationPortGetRunLoopSource(notificationPort).takeRetainedValue()
        observingNotificationPorts = [

            ObservingNotificationPort(
                iteratorType: kIOPublishNotification,
                delegationSelector: #selector(USBDeviceDetectorDelegate.usbDeviceDetector(_:devicesDidAdd:)),
                makeNotification: DevicesDidAddNotification.init
            ),
            
            ObservingNotificationPort(
                iteratorType: kIOTerminatedNotification,
                delegationSelector: #selector(USBDeviceDetectorDelegate.usbDeviceDetector(_:devicesDidRemove:)),
                makeNotification: DevicesDidRemoveNotification.init
            )
        ]
        
        super.init()

        CFRunLoopAddSource(CFRunLoopGetCurrent(), notificationPortRunLoop, .defaultMode)
        
        for observingNotificationPort in observingNotificationPorts {
            
            try! addNotification(observingNotificationPort.iterator) { [unowned self] in
                
                let devices = USBDeviceSequence(rawIterator: $0).devices
                
                delegate?.perform(observingNotificationPort.delegationSelector, with: self, with: devices)
                observingNotificationPort.makeNotification(self, devices).post()
            }
        }
    }
    
    deinit {
        
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notificationPortRunLoop, .defaultMode)
        IONotificationPortDestroy(notificationPort)
        
        notificationHandlers.removeAll()
    }
}

private extension USBDeviceDetector {

    struct ObservingNotificationPort {
    
        var iterator: IOIterator
        var delegationSelector: Selector
        var makeNotification: (USBDeviceDetector, USBDevices) -> NotificationProtocol
    }
    
    class NotificationHandler {

        typealias Callback = (_ iterator: IOIterator) -> Void
        
        let type: String
        let callback: Callback
        
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
}

extension USBDeviceDetector.ObservingNotificationPort {
    
    init(iteratorType: String, delegationSelector: Selector, makeNotification: @escaping (USBDeviceDetector, USBDevices) -> NotificationProtocol) {
        
        self.init(iterator: IOIterator(type: iteratorType), delegationSelector: delegationSelector, makeNotification: makeNotification)
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

//
//  IOObject.swift
//  USBDeviceDetector
//
//  Created by Tomohiro Kumagai on 2021/11/14.
//

import IOKit

public final class IOObject {
    
    public private(set) var rawObject: io_object_t
    
    convenience init?(_ object: io_object_t) {
        
        self.init(retainedObject: object)

        IOObjectRetain(rawObject)
    }
    
    init?(retainedObject object: io_object_t) {
        
        guard object != IO_OBJECT_NULL else {
            
            return nil
        }

        rawObject = object
    }

    deinit {        
        
        invalidate()
    }
    
    public var isValid: Bool {
    
        rawObject != IO_OBJECT_NULL
    }
    
    public func invalidate() {
        
        guard isValid else {
            
            return
        }
        
        IOObjectRelease(rawObject)
        rawObject = IO_OBJECT_NULL
    }
}

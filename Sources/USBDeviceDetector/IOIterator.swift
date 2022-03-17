//
//  IOIterator.swift
//  USBDeviceDetector
//
//  Created by Tomohiro Kumagai on 2021/11/14.
//

import IOKit

public final class IOIterator {
    
    public let type: String
    public private(set) var rawIterator: UnsafeMutablePointer<io_iterator_t>?
    
    init(type: String, retainedIterator iterator: io_iterator_t) {
        
        self.type = type
        self.rawIterator = .allocate(capacity: 1)
        
        rawIterator?.pointee = iterator
    }
    
    convenience init(type: String) {
    
        self.init(type: type, iterator: IO_OBJECT_NULL)
    }
    
    convenience init(type: String, iterator: io_iterator_t) {
        
        self.init(type: type, retainedIterator: iterator)
        IOObjectRetain(iterator)
    }
    
    deinit {

        invalidate()
    }
    
    public var isValid: Bool {
        
        guard let iterator = rawIterator else {
        
            return false
        }
        
        return IOIteratorIsValid(iterator.pointee) != 0
    }
    
    public func invalidate() {
        
        guard isValid else {
        
            return
        }

        defer {
        
            IOObjectRelease(rawIterator!.pointee)
            rawIterator = nil
        }
                
        while let object = next() {

            object.invalidate()
        }
    }
}

extension IOIterator : IteratorProtocol {
    
    public func next() -> IOObject? {

        guard isValid else {
            
            return nil
        }
        
        guard case let iterator = IOIteratorNext(rawIterator!.pointee), let object = IOObject(retainedObject: iterator) else {
            
            return nil
        }
            
        return object
    }
}

extension IOIterator : Sequence {
    
}

//
//  CLLocationManager+LambdaKit.swift
//  Created by Martin Conte Mac Donell on 3/31/15.
//
//  Copyright (c) 2015 Lyft (http://lyft.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import CoreLocation

public typealias LKCoreLocationHandler = LKLocationOrError -> Void

// A global var to produce a unique address for the assoc object handle
private var associatedEventHandle: UInt8 = 0

/**
CLLocationManager with closure callback.

Note that when using startUpdatingLocation(handler) you need to use the counterpart
`stopUpdatingLocationHandler` or you'll leak memory.

Example:

```swift
let locationManager = CLLocationManager()
locationManager.starUpdatingLocation { location in
    println("Location: \(location)")
}
locationManager.stopUpdatingLocationHandler()
```

WARNING: You cannot use closures *and* set a delegate at the same time. Setting a delegate will prevent
closures for being called and setting a closure will overwrite the delegate property.
*/

/**
 An enum that will represent either a location or an error with corresponding associated values.

 - Location A location as reported by Core Location.
 - Error    An error coming from Core Location, for example when location service usage is denied.
 */
public enum LKLocationOrError {
    case Location(CLLocation)
    case Error(NSError)
}

extension CLLocationManager: CLLocationManagerDelegate {

    private var closureWrapper: ClosureWrapper? {
        get {
            return objc_getAssociatedObject(self, &associatedEventHandle) as? ClosureWrapper
        }

        set {
            objc_setAssociatedObject(self, &associatedEventHandle, newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
    Starts monitoring GPS location changes and call the given closure for each change.

    - parameter completion: A closure that will be called passing as the first argument the device's location.
    */
    public func startUpdatingLocation(completion: LKCoreLocationHandler) {
        self.closureWrapper = ClosureWrapper(handler: completion)
        self.delegate = self
        self.startUpdatingLocation()
        if let location = self.location {
            completion(.Location(location))
        }
    }

    /**
    Stops monitoring GPS location changes and cleanup.
    */
    public func stopUpdatingLocationHandler() {
        self.stopUpdatingLocation()
        self.closureWrapper = nil
        self.delegate = nil
    }

    /**
    Request the current location which is reported in the completion handler

    - parameter completion: A closure that will be called with the device's current location.
    */
    @available(iOS 9, watchOS 2, *)
    public func requestLocation(completion: LKCoreLocationHandler) {
        self.closureWrapper = ClosureWrapper(handler: completion)
        self.delegate = self
        self.requestLocation()
        if let location = self.location {
            completion(.Location(location))
        }
    }

#if !os(watchOS)
    /**
    Starts monitoring significant location changes and call the given closure for each change.

    :param: completion A closure that will be called passing as the first argument the device's location.
    */
    public func startMonitoringSignificantLocationChanges(completion: LKCoreLocationHandler) {
        self.closureWrapper = ClosureWrapper(handler: completion)
        self.delegate = self
        self.startMonitoringSignificantLocationChanges()
    }

    /**
    Stops monitoring GPS location changes and cleanup.
    */
    public func stopMonitoringSignificantLocationChangesHandler() {
        self.stopMonitoringSignificantLocationChanges()
        self.closureWrapper = nil
        self.delegate = nil
    }
#endif

    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let handler = self.closureWrapper?.handler, let location = manager.location {
            handler(.Location(location))
        }
    }

    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        self.closureWrapper?.handler(.Error(error))
    }
}

// MARK: - Private Classes

private final class ClosureWrapper {
    private var handler: LKCoreLocationHandler

    init(handler: LKCoreLocationHandler) {
        self.handler = handler
    }
}

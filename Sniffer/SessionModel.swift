//
//  SessionModel.swift
//  Sniffer
//
//  Created by ZapCannon87 on 01/09/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import QuartzCore

class SessionModel {
    
    var index: Int? {
        get {
            return self.dic.value(for: "index")
        }
        set {
            self.dic["index"] = newValue
        }
    }
    
    var date: Double? {
        get {
            return self.dic.value(for: "date")
        }
        set {
            self.dic["date"] = newValue
        }
    }
    
    var method: String? {
        get {
            return self.dic.value(for: "method")
        }
        set {
            self.dic["method"] = newValue
        }
    }
    
    var userAgent: String? {
        get {
            return self.dic.value(for: "userAgent")
        }
        set {
            self.dic["userAgent"] = newValue
        }
    }
    
    var url: String? {
        get {
            return self.dic.value(for: "url")
        }
        set {
            self.dic["url"] = newValue
        }
    }
    
    var localHost: String? {
        get {
            return self.dic.value(for: "localHost")
        }
        set {
            self.dic["localHost"] = newValue
        }
    }
    
    var localPort: Int? {
        get {
            return self.dic.value(for: "localPort")
        }
        set {
            self.dic["localPort"] = newValue
        }
    }
    
    var remoteHost: String? {
        get {
            return self.dic.value(for: "remoteHost")
        }
        set {
            self.dic["remoteHost"] = newValue
        }
    }
    
    var remotePort: Int? {
        get {
            return self.dic.value(for: "remotePort")
        }
        set {
            self.dic["remotePort"] = newValue
        }
    }
    
    var uploadTraffic: Int? {
        get {
            return self.dic.value(for: "uploadTraffic")
        }
        set {
            self.dic["uploadTraffic"] = newValue
        }
    }
    
    var downloadTraffic: Int? {
        get {
            return self.dic.value(for: "downloadTraffic")
        }
        set {
            self.dic["downloadTraffic"] = newValue
        }
    }
    
    enum sessionStatus: String {
        case connect = "Connect"
        case sendRequest = "SendRequest"
        case receiveResponse = "ReceiveResponse"
        case active = "Active"
        case close = "Close"
    }
    
    var status: String? {
        get {
            return self.dic.value(for: "status")
        }
        set {
            self.dic["status"] = newValue
        }
    }
    
    enum timingType: String {
        case establishing = "Establishing"
        case requestSending = "RequestSending"
        case responseReceiving = "ResponseReceiving"
        case transmitting = "Transmitting"
    }
    
    enum timingTypeStatus: String {
        case start = "start"
        case end = "end"
    }
    
    func insertTiming(type: timingType, status: timingTypeStatus) {
        let date: Double = CACurrentMediaTime()
        var timingsDic: [String : [String : Double]]
        if var _timingsDic: [String : [String : Double]] = self.timings {
            var typeDic: [String : Double]
            if let _typeDic: [String : Double] = _timingsDic[type.rawValue] {
                typeDic = _typeDic
            } else {
                typeDic = [status.rawValue : date]
            }
            _timingsDic.updateValue(typeDic, forKey: type.rawValue)
            timingsDic = _timingsDic
        } else {
            timingsDic = [type.rawValue : [status.rawValue : date]]
        }
        self.timings = timingsDic
    }
    
    private(set) var timings: [String : [String : Double]]? {
        get {
            return self.dic.value(for: "timings")
        }
        set {
            self.dic["timings"] = newValue
        }
    }
    
    
    var note: String? {
        get {
            return self.dic.value(for: "note")
        }
        set {
            self.dic["note"] = newValue
        }
    }
    
    var requestHeaders: String? {
        get {
            return self.dic.value(for: "requestHeaders")
        }
        set {
            self.dic["requestHeaders"] = newValue
        }
    }
    
    var responseHeaders: String? {
        get {
            return self.dic.value(for: "responseHeaders")
        }
        set {
            self.dic["responseHeaders"] = newValue
        }
    }
    
    private(set) var dic: [String : Any]
    
    init() {
        self.dic = [:]
    }
    
    init(dic: [String : Any]) {
        self.dic = dic
    }
    
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    
    func value<T>(for key: Key) -> T? {
        guard let any: Any = self[key] else {
            return nil
        }
        if let value: T = any as? T {
            return value
        } else {
            switch T.self {
            case is String.Type:
                switch any {
                case let someInt as Int:
                    return String(someInt) as? T
                case let someDouble as Double:
                    return String(someDouble) as? T
                case let someBool as Bool:
                    return String(someBool) as? T
                default:
                    return nil
                }
            case is Int.Type:
                if let someString: String = any as? String {
                    return Int(someString) as? T
                } else if let someDouble: Double = any as? Double {
                    return Int(someDouble) as? T
                } else {
                    return nil
                }
            case is Double.Type:
                if let someString: String = any as? String {
                    return Double(someString) as? T
                } else if let someInt: Int = any as? Int {
                    return Double(someInt) as? T
                } else {
                    return nil
                }
            case is Bool.Type:
                if let someString: String = any as? String {
                    return Bool(someString) as? T
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
    }
    
}

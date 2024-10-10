//
//  KeyValuePair.swift
//  RCEnvironment
//
//  Created by C.W. Betts on 10/10/24.
//

import Foundation

@objcMembers
class KeyValuePair : NSObject {
    override init() { super.init() }
    
    var key: String = ""
    var value: String = ""
    
    @objc(keyValuePairWithKey:andValue:)
    static func keyValuePairWith(key: String, andValue value: String) -> KeyValuePair {
        let val = KeyValuePair()
        val.key = key
        val.value = value
        return val
    }
    
    override var description: String {
        return "key:\(key), value:\(value)"
    }
    
    func compare(_ other: KeyValuePair) -> ComparisonResult {
        return self.key.compare(other.key)
    }
}

//
//  KeyValuePair.swift
//  RCEnvironment
//
//  Created by C.W. Betts on 10/10/24.
//

import Foundation

@objcMembers
class KeyValuePair : NSObject {
	override convenience init() {
		self.init(key: "", value: "")
	}
    
	init(key: String, value: String) {
		self.key = key
		self.value = value
		super.init()
	}
	
    var key: String = ""
    var value: String = ""
    
    @objc(keyValuePairWithKey:andValue:)
	static func keyValuePairWith(key: String, value: String) -> KeyValuePair {
		return KeyValuePair(key: key, value: value)
    }
    
    override var description: String {
        return "key:\(key), value:\(value)"
    }
    
    func compare(_ other: KeyValuePair) -> ComparisonResult {
        return self.key.compare(other.key)
    }
}

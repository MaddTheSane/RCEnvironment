//
//  KeyValuePair.swift
//  RCEnvironment
//
//  Created by C.W. Betts on 10/10/24.
//

import Foundation

struct KeyValuePair: CustomStringConvertible {    
	init(key: String, value: String) {
		self.key = key
		self.value = value
	}
	
    var key: String = ""
    var value: String = ""
    
	var description: String {
        return "key:\(key), value:\(value)"
    }
    
    func compare(_ other: KeyValuePair) -> ComparisonResult {
        return self.key.compare(other.key)
    }
}

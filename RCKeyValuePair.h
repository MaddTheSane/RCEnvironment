//
//  RCKeyValuePair.h
//  RCEnvironment
//
//  Created by Doug McClure on 09/20/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RCKeyValuePair : NSObject {
    NSString *key;
    NSString *value;
}

+ (RCKeyValuePair *)keyValuePairWithKey:(NSString *)aKey andValue:(NSString *)anObject;

- (NSString *)key;
- (void)setKey:(NSString *)aKey;

- (NSString *)value;
- (void)setValue:(NSString *)anObject;

- (NSComparisonResult)compare:(RCKeyValuePair *)anotherPair;

@end

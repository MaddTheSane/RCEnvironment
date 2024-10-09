//
//  RCKeyValuePair.h
//  RCEnvironment
//
//  Created by Doug McClure on 09/20/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCKeyValuePair : NSObject {
    NSString *key;
    NSString *value;
}

+ (RCKeyValuePair *)keyValuePairWithKey:(NSString *)aKey andValue:(NSString *)anObject;

@property (copy) NSString *key;
@property (copy) NSString *value;

- (NSComparisonResult)compare:(RCKeyValuePair *)anotherPair;

@end

NS_ASSUME_NONNULL_END

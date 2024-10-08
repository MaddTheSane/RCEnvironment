//
//  RCKeyValuePair.m
//  RCEnvironment
//
//  Created by Doug McClure on 09/20/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "RCKeyValuePair.h"


@implementation RCKeyValuePair

+ (RCKeyValuePair *)keyValuePairWithKey:(NSString *)aKey andValue:(NSString *)anObject
{
    RCKeyValuePair *object = [[RCKeyValuePair alloc] init];
    [object setKey:aKey];
    [object setValue:anObject];
    return object;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"key:%@, value:%@", [self key], [self value]];
}

@synthesize key;
@synthesize value;


- (NSComparisonResult)compare:(RCKeyValuePair *)anotherPair
{
    return [[self key] compare:[anotherPair key]];
}

@end

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
    RCKeyValuePair *object = [[[RCKeyValuePair alloc] init] autorelease];
    [object setKey:aKey];
    [object setValue:anObject];
    return object;
}


- (void)dealloc
{
    [self setKey:nil];
    [self setValue:nil];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"key:%@, value:%@", [self key], [self value]];
}


- (NSString *)key
{
    return key;
}

- (void)setKey:(NSString *)aKey
{
    if (key != aKey) {
        id old = key;
        key = [aKey retain];
        [old release];
    }
}


- (NSString *)value
{
    return value;
}

- (void)setValue:(NSString *)anObject
{
    if (value != anObject) {
        id old = value;
        value = [anObject retain];
        [old release];
    }
}


- (NSComparisonResult)compare:(RCKeyValuePair *)anotherPair
{
    return [[self key] compare:[anotherPair key]];
}

@end

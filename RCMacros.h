/*
 *  RCMacros.h
 *  RCEnvironment
 *
 *  Created by Doug McClure on 09/21/2004.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/NSObject.h>

#define RCLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], comment)

#if !defined(MAC_OS_X_VERSION_10_5) || MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
// compiling against 10.4 or before headers
typedef int NSInteger;
typedef unsigned NSUInteger;
#endif

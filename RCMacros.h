/*
 *  RCMacros.h
 *  RCEnvironment
 *
 *  Created by Doug McClure on 09/21/2004.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */


#define RCLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], comment)

//
//  RCKeyValueDataSource.h
//  RCEnvironment
//
//  Created by Doug McClure on Thu May 09 2002.
//

#import <Cocoa/Cocoa.h>

extern NSNotificationName const RCKeyValueDataSourceChangedNotification;

@class KeyValuePair;
@protocol RCKeyValueDataSourceDelegate;

@interface RCKeyValueDataSource : NSObject <NSTableViewDataSource>

@property (copy) NSString *bundleIdentifier;

//! This can be directly hooked up to an NSTableView in IB
@property (nonatomic, strong) IBOutlet NSTableView *tableView;

//! The inspector window
@property (weak) IBOutlet NSWindow *inspectWindow;

// Fields on the inspector window
@property (weak) IBOutlet NSTextField *editKey;
@property (weak) IBOutlet NSText *editValue;

@property (nonatomic, copy) NSDictionary<NSString*,NSString*> *dictionary;

- (IBAction)addItem:(id)sender;
- (IBAction)removeItems:(id)sender;
- (IBAction)editItem:(id)sender;
- (IBAction)endEditItem:(id)sender;

@end


@protocol RCKeyValueDataSourceDelegate <NSObject>
- (BOOL)keyValueDataSource:(RCKeyValueDataSource *)source willSetKeyToString:(NSString *)key;
- (BOOL)keyValueDataSource:(RCKeyValueDataSource *)source willSetValueToString:(NSString *)value;
@end

//
//  RCKeyValueDataSource.h
//  RCEnvironment
//
//  Created by Doug McClure on Thu May 09 2002.
//

#import <Cocoa/Cocoa.h>

extern NSNotificationName const RCKeyValueDataSourceChangedNotification;

@class RCKeyValuePair;
@protocol RCKeyValueDataSourceDelegate;

@interface RCKeyValueDataSource : NSObject <NSTableViewDataSource>
{
    //! This can be directly hooked up to an NSTableView in IB
    NSTableView *tableView;
	
    //! The inspector window
    IBOutlet NSWindow *inspectWindow;
    
    // Fields on the inspector window
    IBOutlet NSTextField *editKey;
    IBOutlet NSText *editValue;

@private
    NSWindow *prefWindow;

    NSMutableArray<RCKeyValuePair*> *values;

    NSString *bundleIdentifier;
	
    NSInteger editRow;
}

@property (copy) NSString *bundleIdentifier;

//! This can be directly hooked up to an NSTableView in IB
@property (nonatomic, retain) IBOutlet NSTableView *tableView;

- (void)setDictionary:(NSDictionary<NSString*,NSString*> *)aDictionary;
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

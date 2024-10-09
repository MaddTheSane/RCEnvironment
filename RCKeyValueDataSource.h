//
//  RCKeyValueDataSource.h
//  RCEnvironment
//
//  Created by Doug McClure on Thu May 09 2002.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSNibDeclarations.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSText.h>
#import <AppKit/NSTextField.h>

extern NSString * const RCKeyValueDataSourceChangedNotification;

@interface RCKeyValueDataSource : NSObject
{
    // This can be directly hooked up to an NSTableView in IB
    IBOutlet NSTableView *tableView;
	IBOutlet NSButton *removeButton;
	IBOutlet NSButton *inspectButton;
	
	IBOutlet NSWindow *inspectWindow;
    
	IBOutlet NSTextField *editKey;
	IBOutlet NSText *editValue;

@private
    NSWindow *prefWindow;

    NSMutableArray *values;

    NSString *bundleIdentifier;
	
	int editRow;
}

- (void)setBundleIdentifier:(NSString *)bundleIdentifier;

- (void)setTableView:(NSTableView *)aTableView;
- (NSTableView *)tableView;

- (void)setDictionary:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionary;

- (IBAction)addItem:(id)sender;
- (IBAction)removeItems:(id)sender;
- (IBAction)editItem:(id)sender;
- (IBAction)endEditItem:(id)sender;

@end


@interface RCKeyValueDataSourceDelegate
- (BOOL)keyValueDataSource:(RCKeyValueDataSource *)source willSetKeyToString:(NSString *)key;
- (BOOL)keyValueDataSource:(RCKeyValueDataSource *)source willSetValueToString:(NSString *)value;
@end

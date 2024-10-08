//
//  RCEnvironmentPref.h
//  RCEnvironment
//
//  Created by Doug McClure on Wed May 08 2002.
//

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#import "RCKeyValueDataSource.h"

@interface RCEnvironmentPref : NSPreferencePane 
{
    // File save/revert/backup buttons
    IBOutlet NSButtonCell *saveButton;
    IBOutlet NSButtonCell *revertButton;
    IBOutlet NSButton *backupButton;
    
    // Buttons for dealing with the key values
    IBOutlet NSButton *addButton;
    IBOutlet NSButton *removeButton;
    IBOutlet NSButton *editButton;
    IBOutlet NSButton *inspectButton;
    
    // Text fields on pages
    IBOutlet NSTextView *aboutField;
    IBOutlet NSTextField *versionField;
    IBOutlet NSTextField *nextLoginField;
    
    // Objects related to editing table view
    IBOutlet NSTableView *tableView;
    IBOutlet NSTableColumn *variableColumn;
    IBOutlet NSTableColumn *valueColumn;
    
    // Control objects on the inspector page
    IBOutlet NSTextField *inspectTitle;
    IBOutlet NSMatrix *inspectButtons;
    
    // Tab view, only need this for doing localization of the tab names
    IBOutlet NSTabView *tabView;
    
    // The data source for editing the page
    IBOutlet RCKeyValueDataSource *keyValueDataSource;
    
@private
    NSString *envDir;
    NSWindow *prefWindow;

    BOOL isDocumentDirty;
}

- (IBAction)revert:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)loadBackup:(id)sender;

- (IBAction)showWebsite:(id)sender;

- (void)updateButtons:(BOOL)checkBackup;

@end

//
//  RCEnvironmentPref.h
//  RCEnvironment
//
//  Created by Doug McClure on Wed May 08 2002.
//

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>

@class KeyValueDataSource;

@interface RCEnvironmentPref : NSPreferencePane
{
    // File save/revert/backup buttons
    IBOutlet NSButton *saveButton;
    IBOutlet NSButton *backupButton;
    
    // Buttons for dealing with the key values
    IBOutlet NSButton *addButton;
    IBOutlet NSButton *removeButton;
    IBOutlet NSButton *inspectButton;
    
    // Text fields on pages
    IBOutlet NSTextView *aboutField;
    IBOutlet NSTextField *versionField;
    
    // Objects related to editing table view
    IBOutlet NSTableView *tableView;
    
    // Tab view, only need this for doing localization of the tab names
    IBOutlet NSTabView *tabView;
    
    // The data source for editing the page
    IBOutlet KeyValueDataSource *keyValueDataSource;
    
@private
    NSURL *envDir;
    NSWindow *prefWindow;

    BOOL isDocumentDirty;
}

- (IBAction)revert:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)loadBackup:(id)sender;

- (IBAction)showWebsite:(id)sender;

- (void)updateButtons:(BOOL)checkBackup;

@end

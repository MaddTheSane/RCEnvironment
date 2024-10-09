//
//  RCEnvironmentPref.h
//  RCEnvironment
//
//  Created by Doug McClure on Wed May 08 2002.
//

#import <PreferencePanes/PreferencePanes.h>
#import "RCKeyValueDataSource.h"

@interface RCEnvironmentPref : NSPreferencePane 
{
    IBOutlet NSButtonCell *saveBtn;
    IBOutlet NSButtonCell *revertBtn;
    IBOutlet NSButton *backupBtn;
    
    IBOutlet NSTabView *tabView;
    IBOutlet NSTextView *aboutField;
    IBOutlet NSTextField *versionField;
    IBOutlet NSTextField *nextLoginField;
    
    IBOutlet NSTableColumn *variableColumn;
    IBOutlet NSTableColumn *valueColumn;

    IBOutlet RCKeyValueDataSource *keyValueDataSource;
    
    IBOutlet NSTextField *inspectTitle;
    IBOutlet NSMatrix *inspectBtns;
    
    IBOutlet NSButton *addBtn;
    IBOutlet NSButton *removeBtn;
    IBOutlet NSButton *editBtn;

@private
    NSString *envDir;
    NSWindow *prefWindow;

    BOOL isDocumentDirty;
}

- (IBAction)revert:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)loadBackup:(id)sender;

- (IBAction)showWebsite:(id)sender;

@end

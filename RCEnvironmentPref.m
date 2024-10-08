/*
 * Copyright (c) 2002 Doug McClure
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
			  * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
			  * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "RCEnvironmentPref.h"
#import "RCMacros.h"

NSString *ENVIRONMENT_DIR = @".MacOSX";
NSString *ENVIRONMENT_FILE = @"environment.plist";
NSString *ENVIRONMENT_BACKUP = @"environment~.plist";


@interface NSFileManager (Extension)
- (BOOL)isCreatableFileAtPath:(NSString *)path;
@end


@implementation RCEnvironmentPref

- (void)mainViewDidLoad
{    
    envDir = [[NSHomeDirectory() stringByAppendingPathComponent:ENVIRONMENT_DIR] retain];
    
    [super mainViewDidLoad];
    
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    
    NSDictionary *infoDictionary = [myBundle infoDictionary];
    [keyValueDataSource setBundleIdentifier:[infoDictionary objectForKey:@"CFBundleIdentifier"]];
    [versionField setStringValue:[infoDictionary objectForKey:@"CFBundleVersion"]];
    
    NSString *aboutTextFile = [myBundle pathForResource:@"AboutText" ofType:@"rtf"];
    NSScrollView *aboutTextScrollView = [aboutField enclosingScrollView];
    [aboutField readRTFDFromFile:aboutTextFile];
    [aboutField setDrawsBackground:NO];
    [aboutField setTextContainerInset:NSZeroSize];
    [aboutField sizeToFit];
    [aboutTextScrollView setDrawsBackground:NO];
    [aboutTextScrollView setHasVerticalScroller:NSHeight([aboutField frame]) > NSHeight([aboutTextScrollView frame])];
    
    [saveButton setTitle:RCLocalizedString(@"Save", @"Save environment")];
    [revertButton setTitle:RCLocalizedString(@"Revert", @"Revert to saved environment")];
    [backupButton setTitle:RCLocalizedString(@"LoadBackup", @"Load backup")];
    [[variableColumn headerCell] setStringValue:RCLocalizedString(@"Variable", @"Variable column")];
    [[valueColumn headerCell] setStringValue:RCLocalizedString(@"Value", @"Value column")];
    [nextLoginField setStringValue:RCLocalizedString(@"NextLoginWarning", @"Warning about next login")];
    
    [[tabView tabViewItemAtIndex:0] setLabel:RCLocalizedString(@"Environment", @"Environment tab label")];
    [[tabView tabViewItemAtIndex:1] setLabel:RCLocalizedString(@"About", @"About tab label")];
    
    [inspectTitle setStringValue:RCLocalizedString(@"EditVariable", @"Edit variable label")];
    [[inspectButtons cellAtRow:0 column:0] setTitle:RCLocalizedString(@"Cancel", @"Cancel button label")];
    [[inspectButtons cellAtRow:0 column:1] setTitle:RCLocalizedString(@"Save", @"Save button label")];
    
    [addButton setToolTip:RCLocalizedString(@"AddItemTip", @"Add an item")];
    [removeButton setToolTip:RCLocalizedString(@"RemoveItemTip", @"Remove item(s)")];
    [editButton setToolTip:RCLocalizedString(@"EditItemTip", @"Edit item")];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyValueDataSourceDidChange:)
                                                 name:RCKeyValueDataSourceChangedNotification
                                               object:keyValueDataSource];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
					     selector:@selector(tableViewSelectionDidChange:)
						 name:NSTableViewSelectionDidChangeNotification
					       object:tableView];
}

- (void)didSelect
{
    prefWindow = [tabView window];
    [self revert:self];
}


- (void)updateButtons:(BOOL)checkBackup
{
    [saveButton setEnabled:isDocumentDirty];
    
    NSInteger selectedRows = [tableView numberOfSelectedRows];
    [removeButton setEnabled:(selectedRows > 0)];
    [inspectButton setEnabled:(selectedRows == 1)];
    
    if ( checkBackup ) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir;
	
        NSString *backupFile = [envDir stringByAppendingPathComponent:ENVIRONMENT_BACKUP];
	
        [backupButton setEnabled:([fileManager fileExistsAtPath:backupFile isDirectory:&isDir] &&
				  !isDir &&
				  [fileManager isReadableFileAtPath:backupFile])];
    }
}


- (void)loadEnvironmentFile:(NSString *)file isMainFile:(BOOL)isMainFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    
    NSString *envFile = [envDir stringByAppendingPathComponent:file];
    
    if ( ![fileManager fileExistsAtPath:envFile isDirectory:&isDir] ) {
        if ( !isMainFile ) {
            NSBeginAlertSheet(RCLocalizedString(@"FileError", @"File error"),
			      nil, nil, nil, prefWindow, nil, nil, nil, nil,
			      RCLocalizedString(@"FileDoesNotExist", @"File does not exist"), ENVIRONMENT_DIR, file);
        }
        else {
            [keyValueDataSource setDictionary:nil];
            isDocumentDirty = NO;
        }
    }
    else {
        BOOL isError = NO;
	
        if ( isDir ) {
            NSBeginAlertSheet(RCLocalizedString(@"FileError", @"File error"),
			      nil, nil, nil, prefWindow, nil, nil, nil, nil,
                              RCLocalizedString(@"FileIsNotFile", @"File is not a file"), ENVIRONMENT_DIR, file);
            isError = YES;
        }
        else if ( ![fileManager isReadableFileAtPath:envFile] ) {
            NSBeginAlertSheet(RCLocalizedString(@"FileError", @"File error"),
			      nil, nil, nil, prefWindow, nil, nil, nil, nil,
                              RCLocalizedString(@"FileIsNotReadable", @"File is not readable"), ENVIRONMENT_DIR, file);
            isError = YES;
        }
        else {
            [keyValueDataSource setDictionary:[NSDictionary dictionaryWithContentsOfFile:envFile]];
            isDocumentDirty = !isMainFile;
        }
        
        if ( isError && isMainFile ) {
            [keyValueDataSource setDictionary:nil];
            isDocumentDirty = NO;
        }
    }
    
    [self updateButtons:YES];
}

- (IBAction)loadBackup:(id)sender
{
    [[keyValueDataSource tableView] abortEditing];
    [self loadEnvironmentFile:ENVIRONMENT_BACKUP isMainFile:NO];
}

- (IBAction)revert:(id)sender
{
    [[keyValueDataSource tableView] abortEditing];
    [self loadEnvironmentFile:ENVIRONMENT_FILE isMainFile:YES];
}

- (IBAction)save:(id)sender
{
    if ( [prefWindow makeFirstResponder:prefWindow] ) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *envFile = [envDir stringByAppendingPathComponent:ENVIRONMENT_FILE];
        NSString *backupFile = [envDir stringByAppendingPathComponent:ENVIRONMENT_BACKUP];
	
        if ( ![fileManager fileExistsAtPath:envDir] ) {
            [fileManager createDirectoryAtPath:envDir attributes:@{}];
        }
	
        // Remove backup file, ignore error if could not remove it, will deal with that below
        [fileManager removeFileAtPath:backupFile handler:nil];
	
        if ( [fileManager fileExistsAtPath:envFile] && ![fileManager copyPath:envFile toPath:backupFile handler:nil] ) {
            NSBeginAlertSheet(RCLocalizedString(@"BackupError", @"Backup file error"),
			      nil, nil, nil, prefWindow, nil, nil, nil, nil,
                              RCLocalizedString(@"BackupFileNotWritable", @"Backup error unable to write"), ENVIRONMENT_DIR, ENVIRONMENT_BACKUP);
        }
        else if ( ![fileManager isCreatableFileAtPath:envFile] ) {
            NSBeginAlertSheet(RCLocalizedString(@"FileError", @"File error"),
			      nil, nil, nil, prefWindow, nil, nil, nil, nil,
                              RCLocalizedString(@"FileNotWritable", @"File can not be written"), ENVIRONMENT_DIR, ENVIRONMENT_FILE);
        }
        else {
            [[keyValueDataSource dictionary] writeToFile:envFile atomically:NO];
            isDocumentDirty = NO;
            [self updateButtons:YES];
        }
    }
}


- (IBAction)showWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.rubicode.com/"]];
}


- (void)keyValueDataSourceDidChange:(NSNotification *)notification
{
    // This method is the notification that gets posted from the RCKeyValueDataSource
    // to let us know that a change happened with the data
    isDocumentDirty = YES;
    [self updateButtons:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self updateButtons:NO];
}

@end


@implementation NSFileManager(Extension)
- (BOOL)isCreatableFileAtPath:(NSString *)path
{
    if ( [self fileExistsAtPath:path] ) {
        // Return if we can write onto the file
        return [self isWritableFileAtPath:path];
    }
    
    // Return if we can write to the directory that we want the file
    return [self isWritableFileAtPath:[path stringByDeletingLastPathComponent]];
}
@end


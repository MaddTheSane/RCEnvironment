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

static NSString *const ENVIRONMENT_DIR = @".MacOSX";
static NSString *const ENVIRONMENT_FILE = @"environment.plist";
static NSString *const ENVIRONMENT_BACKUP = @"environment~.plist";


@interface NSFileManager (Extension)
- (BOOL)isCreatableFileAtPath:(NSString *)path;
- (BOOL)isCreatableFileAtURL:(NSURL *)path;
@end


@implementation RCEnvironmentPref

- (void)mainViewDidLoad
{    
    envDir = [[[NSFileManager defaultManager] homeDirectoryForCurrentUser] URLByAppendingPathComponent:ENVIRONMENT_DIR];
    
    [super mainViewDidLoad];
    
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    
    NSDictionary *infoDictionary = [myBundle infoDictionary];
    [keyValueDataSource setBundleIdentifier:[infoDictionary objectForKey:@"CFBundleIdentifier"]];
    [versionField setStringValue:[infoDictionary objectForKey:@"CFBundleVersion"]];
    
    NSURL *aboutTextFile = [myBundle URLForResource:@"AboutText" withExtension:@"rtf"];
    NSScrollView *aboutTextScrollView = [aboutField enclosingScrollView];
    [aboutField readRTFDFromFile:aboutTextFile.path];
    [aboutField setDrawsBackground:NO];
    [aboutField setTextContainerInset:NSZeroSize];
    [aboutField sizeToFit];
    [aboutTextScrollView setDrawsBackground:NO];
    [aboutTextScrollView setHasVerticalScroller:NSHeight([aboutField frame]) > NSHeight([aboutTextScrollView frame])];
    
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
	
        NSURL *backupFile = [envDir URLByAppendingPathComponent:ENVIRONMENT_BACKUP];
	
        [backupButton setEnabled:([fileManager fileExistsAtPath:backupFile.path isDirectory:&isDir] &&
                                  !isDir &&
                                  [fileManager isReadableFileAtPath:backupFile.path])];
    }
}


- (void)loadEnvironmentFile:(NSString *)file isMainFile:(BOOL)isMainFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    
    NSURL *envFile = [envDir URLByAppendingPathComponent:file];
    
    if ( ![fileManager fileExistsAtPath:envFile.path isDirectory:&isDir] ) {
        if ( !isMainFile ) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = RCLocalizedString(@"FileError", @"File error");
            alert.informativeText = [NSString localizedStringWithFormat:RCLocalizedString(@"FileDoesNotExist", @"File does not exist"), ENVIRONMENT_DIR, file];
            [alert beginSheetModalForWindow:prefWindow completionHandler:^(NSModalResponse returnCode) {
                
            }];
        } else {
            [keyValueDataSource setDictionary:nil];
            isDocumentDirty = NO;
        }
    } else {
        BOOL isError = NO;
	
        if ( isDir ) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = RCLocalizedString(@"FileError", @"File error");
            alert.informativeText = [NSString localizedStringWithFormat:RCLocalizedString(@"FileIsNotFile", @"File is not a file"), ENVIRONMENT_DIR, file];
            [alert beginSheetModalForWindow:prefWindow completionHandler:^(NSModalResponse returnCode) {
                
            }];
            isError = YES;
        } else if ( ![fileManager isReadableFileAtPath:envFile.path] ) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = RCLocalizedString(@"FileError", @"File error");
            alert.informativeText = [NSString localizedStringWithFormat:RCLocalizedString(@"FileIsNotReadable", @"File is not readable"), ENVIRONMENT_DIR, file];
            [alert beginSheetModalForWindow:prefWindow completionHandler:^(NSModalResponse returnCode) {
                
            }];
            isError = YES;
        } else {
            [keyValueDataSource setDictionary:[NSDictionary dictionaryWithContentsOfURL:envFile]];
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
        NSURL *envFile = [envDir URLByAppendingPathComponent:ENVIRONMENT_FILE];
        NSURL *backupFile = [envDir URLByAppendingPathComponent:ENVIRONMENT_BACKUP];
	
        if ( ![fileManager fileExistsAtPath:envDir.path] ) {
            [fileManager createDirectoryAtURL:envDir withIntermediateDirectories:YES attributes:nil error:NULL];
        }
	
        // Remove backup file, ignore error if could not remove it, will deal with that below
        [fileManager removeItemAtURL:backupFile error:nil];
	
        if ( [fileManager fileExistsAtPath:envFile.path] && ![fileManager copyItemAtURL:envFile toURL:backupFile error:NULL] ) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = RCLocalizedString(@"BackupError", @"Backup file error");
            alert.informativeText = [NSString localizedStringWithFormat:RCLocalizedString(@"BackupFileNotWritable", @"Backup error unable to write"), ENVIRONMENT_DIR, ENVIRONMENT_BACKUP];
            [alert beginSheetModalForWindow:prefWindow completionHandler:^(NSModalResponse returnCode) {
                
            }];
        } else if ( ![fileManager isCreatableFileAtURL:envFile] ) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = RCLocalizedString(@"FileError", @"File error");
            alert.informativeText = [NSString localizedStringWithFormat:RCLocalizedString(@"FileNotWritable", @"File can not be written"), ENVIRONMENT_DIR, ENVIRONMENT_BACKUP];
            [alert beginSheetModalForWindow:prefWindow completionHandler:^(NSModalResponse returnCode) {
                
            }];
        } else {
            [[keyValueDataSource dictionary] writeToURL:envFile atomically:NO];
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

- (BOOL)isCreatableFileAtURL:(NSURL *)path {
    if ([path checkResourceIsReachableAndReturnError:NULL]) {
        NSNumber *value;
        if ([path getResourceValue:&value forKey:NSURLIsWritableKey error:NULL] && value.boolValue) {
            // Return if we can write onto the file
            return YES;
        }

        return NO;
    }
    
    NSURL *superPath = [path URLByDeletingLastPathComponent];
    NSNumber *value;
    // Return if we can write to the directory that we want the file
    return ([superPath getResourceValue:&value forKey:NSURLIsWritableKey error:NULL] && value.boolValue);
}

@end


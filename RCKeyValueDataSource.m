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

#import "RCKeyValueDataSource.h"
#import "RCKeyValuePair.h"
#import "RCMacros.h"
#import "RCEnvironmentPref.h"
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSPanel.h>

// The column in the tableView must have an identifier named this way
#define KEY_COLUMN_ID	@"key"

NSString * const RCKeyValueDataSourceChangedNotification = @"RCKeyValueDataSourceChangedNotification";

@interface RCKeyValueDataSource()
- (void)_sortKeys;
- (BOOL)_endEditing;
@end

@implementation RCKeyValueDataSource

- (id)init
{
    if (self = [super init]) {
        editRow = -1;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [values release];
    [tableView release];
    
    [super dealloc];
}

@synthesize bundleIdentifier;


- (void)setTableView:(NSTableView *)aTableView
{
    if ( tableView != nil ) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSControlTextDidEndEditingNotification
                                                      object:tableView];
    }
    
    id old = tableView;
    tableView = [aTableView retain];
    [old release];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_tableViewDidEndEditing:)
                                                 name:NSControlTextDidEndEditingNotification
                                               object:tableView];
}
@synthesize tableView;
@dynamic dictionary;

- (void)setDictionary:(NSDictionary<NSString*,NSString*> *)aDictionary
{
    if (values) {
        [values release];
    }
    values = [[NSMutableArray alloc] init];
    
    for (NSString *key in aDictionary) {
        [values addObject:[RCKeyValuePair keyValuePairWithKey:key andValue:aDictionary[key]]];
    }
    
    [self _sortKeys];
}

- (NSDictionary<NSString*,NSString*> *)dictionary
{
    // The following code is only available in Panther, that is the valueForKey: support on
    // NSArray.  The code that the method uses is technically faster and cheaper, but the
    // Panther code is certainly way more elegant.
    //return [NSDictionary dictionaryWithObjects:[values valueForKey:@"value"] forKeys:[values valueForKey:@"key"]];
    
    // Non-Panther code
    NSMutableDictionary<NSString*,NSString*> *dictionary = [NSMutableDictionary dictionary];
    
    for (RCKeyValuePair *pair in values) {
        dictionary[pair.key] = pair.value;
    }
    
    return dictionary;
}


- (NSUInteger)indexOfKey:(NSString *)aKey
{
    NSInteger i = 0, count = [values count];
    
    for ( ; i < count; i++ ) {
        if ( [values[i].key isEqualToString:aKey] ) {
            return i;
        }
    }
    
    return NSNotFound;
}

- (BOOL)keyExistsAlready:(NSString *)aKey
{
    return [self indexOfKey:aKey] != NSNotFound;
}

- (IBAction)addItem:(id)sender
{
    if ( [self _endEditing] ) {
        [[tableView window] endEditingFor:tableView];
        
        int keyOffset = 2;
        NSString *defaultKey = RCLocalizedString(@"DefaultKey", @"Default key");
        NSString *key = defaultKey;
        
        while ( [self keyExistsAlready:key] ) {
            key = [defaultKey stringByAppendingFormat:@"%d", keyOffset++];
        }
        
        [values addObject:[RCKeyValuePair keyValuePairWithKey:key andValue:RCLocalizedString(@"DefaultValue", @"Default value")]];
        
        [tableView reloadData];
        
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:([values count]-1)] byExtendingSelection:NO];
        [tableView editColumn:0 row:([values count]-1) withEvent:nil select:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKeyValueDataSourceChangedNotification object:self];
    }
}

- (IBAction)removeItems:(id)sender
{
    if ( [self _endEditing] ) {
        NSIndexSet *selectedRows = [tableView selectedRowIndexes];
        
        if ( [selectedRows count] > 0 ) {
            [values removeObjectsAtIndexes:selectedRows];
            
            [tableView reloadData];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RCKeyValueDataSourceChangedNotification object:self];
        }
    }
}

- (IBAction)editItem:(id)sender
{
    if ( [self _endEditing] ) {
        [[tableView window] endEditingFor:tableView];
        
        editRow = [tableView selectedRow];
        
        if ( editRow != -1 ) {
            RCKeyValuePair *data = [values objectAtIndex:editRow];
            [editKey setStringValue:[data key]];
            [editValue setString:[data value]];
            
            [[tableView window] beginSheet:inspectWindow completionHandler:^(NSModalResponse returnCode) {
                
            }];
        }
    }
}

- (IBAction)endEditItem:(id)sender
{
    if ( [[sender selectedCell] tag] == 1 ) {
        [[values objectAtIndex:editRow] setValue:[editValue string]];
    }
    
    editRow = -1;
    [self _sortKeys]; /* In case the key was being renamed when editItem: was called */
    [[tableView window] endSheet:inspectWindow];
    [inspectWindow close];
}


// Support methods for above, should not be called by others

- (BOOL)_endEditing
{
    return [[tableView window] makeFirstResponder:[tableView window]];
}

- (void)_sortKeys
{
    if ( editRow == -1 && [tableView editedRow] == -1 ) {
        NSString *selectedKey = nil;
        
        if ([tableView selectedRow] >= 0) {
            selectedKey = [[values objectAtIndex:[tableView selectedRow]] key];
        }
        
        [values sortUsingSelector:@selector(compare:)];
        [tableView reloadData];
        
        if (selectedKey != nil) {
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self indexOfKey:selectedKey]] byExtendingSelection:NO];
        }
    }
}


- (void)_tableViewDidEndEditing:(NSNotification *)notification
{
    // Once the table is done editing, sort the rows based on the keys
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_sortKeys) object:nil];
    [self performSelector:@selector(_sortKeys) withObject:nil afterDelay:0];
}


// Table datasource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [values count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    RCKeyValuePair *data = [values objectAtIndex:rowIndex];
    return [[tableColumn identifier] isEqual:KEY_COLUMN_ID] ? [data key] : [data value];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)objectValue forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (objectValue == nil) {
        objectValue = @"";
    }
    
    RCKeyValuePair *data = [values objectAtIndex:rowIndex];
    [[tableColumn identifier] isEqual:KEY_COLUMN_ID] ? [data setKey:objectValue] : [data setValue:objectValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKeyValueDataSourceChangedNotification object:self];
}


// Delegate methods

- (BOOL)control:(NSControl *)control isValidObject:(id)object
{
    // Check first if we are trying to set the VALUE value
    if ( ![[[[tableView tableColumns] objectAtIndex:[tableView editedColumn]] identifier] isEqual:KEY_COLUMN_ID] ) {
        NSRange dollarRange = [object rangeOfString:@"$"];
        
        if ( dollarRange.length > 0 ) {
            NSString *defaultsKey = [[bundleIdentifier stringByAppendingString:@".NoValueWarning"] retain];
            
            if ( ![[NSUserDefaults standardUserDefaults] boolForKey:defaultsKey] ) {
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = RCLocalizedString(@"ValueWarning", @"Value warning");
                alert.informativeText = RCLocalizedString(@"DollarValueWarning", @"Warning about using $ in values.");
                [alert addButtonWithTitle:RCLocalizedString(@"Continue", @"Continue")];
                [alert addButtonWithTitle:RCLocalizedString(@"DontShowAgain", @"Don't Show Again")];
                [alert beginSheetModalForWindow:tableView.window completionHandler:^(NSModalResponse returnCode) {
                    if (returnCode == NSAlertSecondButtonReturn) {
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:defaultsKey];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    [defaultsKey release];
                }];
                [alert autorelease];
            }
        }
    }
    
    // Must be trying to set the KEY value, but it was a zero
    else if ( [(NSString *)object length] == 0 ) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = RCLocalizedString(@"InvalidKey", @"Invalid Key");
        alert.informativeText = RCLocalizedString(@"ZeroLengthKey", @"Non-zero length strings only");
        [alert beginSheetModalForWindow:tableView.window completionHandler:^(NSModalResponse returnCode) {
            
        }];
        [alert release];
        return NO;
    }
    
    // If the user entered a new value for the key and the key exists in the data source already
    else if ( ![[[values objectAtIndex:[tableView editedRow]] key] isEqualToString:object] && [self keyExistsAlready:object] ) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = RCLocalizedString(@"InvalidKey", @"Invalid Key");
        alert.informativeText = RCLocalizedString(@"KeyExists", @"Key already exists.");
        [alert beginSheetModalForWindow:tableView.window completionHandler:^(NSModalResponse returnCode) {
            
        }];
        [alert autorelease];
        return NO;
    }
    
    // If the key was set to PATH, make sure the complain
    else if ( [object isEqualToString:@"PATH"] ) {
        NSString *defaultsKey = [[bundleIdentifier stringByAppendingString:@".NoPathWarning"] retain];
        
        // Only do it if the user hasn't said they should ignore further warnings on this issue.
        if ( ![[NSUserDefaults standardUserDefaults] boolForKey:defaultsKey] ) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = RCLocalizedString(@"KeyWarning", @"Key warning");
            alert.informativeText = RCLocalizedString(@"PathKeyWarning", @"Warning about using PATH");
            [alert addButtonWithTitle:RCLocalizedString(@"Continue", @"Continue")];
            [alert addButtonWithTitle:RCLocalizedString(@"DontShowAgain", @"Don't Show Again")];
            [alert beginSheetModalForWindow:tableView.window completionHandler:^(NSModalResponse returnCode) {
                if (returnCode == NSAlertSecondButtonReturn) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:defaultsKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                [defaultsKey release];
            }];
            [alert autorelease];
        }
    }
    
    return YES;
}

@end

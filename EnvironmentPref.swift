//
//  EnvironmentPref.swift
//  RCEnvironment
//
//  Created by C.W. Betts on 10/13/24.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

import Cocoa
import PreferencePanes

private let ENVIRONMENT_DIR = ".MacOSX";
private let ENVIRONMENT_FILE = "environment.plist";
private let ENVIRONMENT_BACKUP = "environment~.plist";


public class EnvironmentPref : NSPreferencePane {
	// File save/revert/backup buttons
	@IBOutlet weak var saveButton: NSButton!
	@IBOutlet weak var backupButton: NSButton!
	
	// Buttons for dealing with the key values
	@IBOutlet weak var addButton: NSButton!
	@IBOutlet weak var removeButton: NSButton!
	@IBOutlet weak var inspectButton: NSButton!
	
	// Text fields on pages
	@IBOutlet weak var aboutField: NSTextView!
	@IBOutlet weak var versionField: NSTextField!
	
	/// Objects related to editing table view
	@IBOutlet weak var tableView: NSTableView!
	
	/// The data source for editing the page
	@IBOutlet weak var keyValueDataSource: KeyValueDataSource!
	
	private var envDir: URL! = nil
	private var prefWindow: NSWindow? = nil
	private var isDocumentDirty: Bool = false
	
	public override var mainNibName: String {
		return "RCEnvironmentPref"
	}
	
	public override func mainViewDidLoad() {
		envDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(ENVIRONMENT_DIR) 

		super.mainViewDidLoad()
		
		let myBundle = Bundle(for: type(of: self))
		
		let infoDictionary = myBundle.infoDictionary!
		keyValueDataSource.bundleIdentifier = infoDictionary["CFBundleIdentifier"] as? String
		versionField.stringValue = infoDictionary["CFBundleVersion"] as? String ?? "unknown"
		
		if let aboutTextFile = myBundle.url(forResource: "AboutText", withExtension: "rtf") {
			var aboutTextScrollView = aboutField.enclosingScrollView!
			aboutField.readRTFD(fromFile: aboutTextFile.path)
			aboutField.drawsBackground = false
			aboutField.textContainerInset = .zero
			aboutField.sizeToFit()
			aboutTextScrollView.drawsBackground = false
			aboutTextScrollView.hasVerticalScroller = aboutField.frame.height > aboutTextScrollView.frame.height
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyValueDataSourceDidChange(_:)), name: KeyValueDataSource.changedNotification, object: keyValueDataSource)
		
		NotificationCenter.default.addObserver(self, selector: #selector(tableViewSelectionDidChange(_:)), name: NSTableView.selectionDidChangeNotification, object: tableView)
	}
	
	public override func didSelect() {
		prefWindow = tableView.window
		revert(self)
	}
	
	func updateButtons(checkBackup: Bool = false) {
		saveButton.isEnabled = isDocumentDirty
		
		let selectedRows = tableView.numberOfSelectedRows
		removeButton.isEnabled = selectedRows > 0
		inspectButton.isEnabled = selectedRows == 1
		
		if checkBackup {
			var isDir: ObjCBool = false
			let fileManager = FileManager.default
			let backupFile = envDir!.appendingPathComponent(ENVIRONMENT_BACKUP)
			backupButton.isEnabled = fileManager.fileExists(atPath: backupFile.path, isDirectory: &isDir) &&
			!isDir.boolValue &&
			!fileManager.isReadableFile(atPath: backupFile.path)
		}
	}

	private func loadEnvironmentFile(_ file: String, isMainFile: Bool) {
		let myBundle = Bundle(for: type(of: self))
		let fileManager = FileManager.default
		var isDir: ObjCBool = false
		
		let envFile = envDir!.appendingPathComponent(file)
		
		if !fileManager.fileExists(atPath: envFile.path, isDirectory: &isDir) {
			if !isMainFile {
				let alert = NSAlert()
				alert.messageText = NSLocalizedString("FileError", bundle: myBundle, comment: "File error")
				alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("FileDoesNotExist", bundle: myBundle, comment: "File does not exist"), ENVIRONMENT_DIR, file)
				alert.beginSheetModal(for: prefWindow!) { response in
					
				}
			} else {
				keyValueDataSource.dictionary = [:]
				isDocumentDirty = false
			}
		} else {
			var isError: ObjCBool = false
			
			if isDir.boolValue {
				let alert = NSAlert()
				alert.messageText = NSLocalizedString("FileError", bundle: myBundle, comment: "File error")
				alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("FileIsNotFile", bundle: myBundle, comment: "File is not a file"), ENVIRONMENT_DIR, file)
				alert.beginSheetModal(for: prefWindow!) { response in
					
				}
				isError = true
			} else if !fileManager.isReadableFile(atPath: envFile.path) {
				let alert = NSAlert()
				alert.messageText = NSLocalizedString("FileError", bundle: myBundle, comment: "File error")
				alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("FileIsNotReadable", bundle: myBundle, comment: "File is not readable"), ENVIRONMENT_DIR, file)
				alert.beginSheetModal(for: prefWindow!) { response in
					
				}
				isError = true
			} else {
				keyValueDataSource.dictionary = NSDictionary(contentsOfFile: envFile.path) as? [String: String] ?? [:]
				isDocumentDirty = !isMainFile
			}
			
			if isError.boolValue, isMainFile {
				keyValueDataSource.dictionary = [:]
				isDocumentDirty = false
			}
		}
		
		updateButtons(checkBackup: true)
	}
	
	@IBAction func loadBackup(_ sender: Any) {
		keyValueDataSource.tableView.abortEditing()
		loadEnvironmentFile(ENVIRONMENT_BACKUP, isMainFile: false)
	}

	@IBAction func revert(_ sender: Any) {
		keyValueDataSource.tableView.abortEditing()
		loadEnvironmentFile(ENVIRONMENT_FILE, isMainFile: true)
	}
	
	@IBAction func save(_ sender: Any) {
		let myBundle = Bundle(for: type(of: self))
		guard prefWindow?.makeFirstResponder(prefWindow) ?? false else {
			return
		}
		let fileManager = FileManager.default
		let envFile = envDir!.appendingPathComponent(ENVIRONMENT_FILE)
		let backupFile = envDir!.appendingPathComponent(ENVIRONMENT_BACKUP)
		if !fileManager.fileExists(atPath: envDir.path) {
			try? fileManager.createDirectory(at: envDir, withIntermediateDirectories: true)
		}
		
		// Remove backup file, ignore error if could not remove it, will deal with that below
		try? fileManager.removeItem(at: backupFile)
		
		if !fileManager.fileExists(atPath: envFile.path) && ((try? fileManager.copyItem(at: backupFile, to: envFile)) == nil) {
			let alert = NSAlert()
			alert.messageText = NSLocalizedString("BackupError", bundle: myBundle, comment: "Backup file error")
			alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("BackupFileNotWritable", bundle: myBundle, comment: "Backup error unable to write"), ENVIRONMENT_DIR, ENVIRONMENT_BACKUP)
			alert.beginSheetModal(for: prefWindow!) { response in
				
			}
		} else if !fileManager.isCreatableFile(at: envFile) {
			let alert = NSAlert()
			alert.messageText = NSLocalizedString("FileError", bundle: myBundle, comment: "File error")
			alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("FileNotWritable", bundle: myBundle, comment: "File can not be written"), ENVIRONMENT_DIR, ENVIRONMENT_BACKUP)
			alert.beginSheetModal(for: prefWindow!) { response in
				
			}
		} else {
			(keyValueDataSource.dictionary as NSDictionary).write(to: envFile, atomically: false)
			isDocumentDirty = false
			updateButtons(checkBackup: true)
		}
	}
	
	@IBAction func showWebsite(_ sender: Any) {
		NSWorkspace.shared.open(URL(string: "http://www.rubicode.com/")!)
	}
	
	@objc
	private func keyValueDataSourceDidChange(_ notification: Notification) {
		// This method is the notification that gets posted from the RCKeyValueDataSource
		// to let us know that a change happened with the data
		isDocumentDirty = true
		updateButtons()
	}
	
	@objc
	private func tableViewSelectionDidChange(_ notification: Notification) {
		updateButtons()
	}
}

private extension FileManager {
	func isCreatableFile(at path: URL) -> Bool {
		if ((try? path.checkResourceIsReachable()) ?? false) {
			
			do {
				let value = try path.resourceValues(forKeys: [.isWritableKey])
				// Return if we can write onto the file
				return value.isWritable ?? false
			} catch {
				return false
			}
			
		}
		
		let superPath = path.deletingLastPathComponent()
		// Return if we can write to the directory that we want the file
		do {
			let value = try superPath.resourceValues(forKeys: [.isWritableKey])
			return value.isWritable ?? false
		} catch {
			return false
		}
	}
}

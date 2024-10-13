//
//  KeyValueDataSource.swift
//  RCEnvironment
//
//  Created by C.W. Betts on 10/12/24.
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

/// The column in the tableView must have an identifier named this way
private let KEY_COLUMN_ID = NSUserInterfaceItemIdentifier(rawValue: "key")


class KeyValueDataSource : NSObject, NSTableViewDataSource, NSControlTextEditingDelegate {
	public static let changedNotification = NSNotification.Name(rawValue: "RCKeyValueDataSourceChangedNotification")
	
	var bundleIdentifier: String!
	
	/// This can be directly hooked up to an NSTableView in IB
	@IBOutlet var tableView: NSTableView! {
		willSet {
			if let tableView {
				NotificationCenter.default.removeObserver(self,
														  name: NSControl.textDidEndEditingNotification,
														  object: tableView)
			}
		}
		didSet {
			if let tableView {
				NotificationCenter.default.addObserver(self,
													   selector: #selector(_tableViewDidEndEditing(_:)),
													   name: NSControl.textDidEndEditingNotification,
													   object: tableView)
			}
		}
	}
	
	/// The inspector window
	@IBOutlet weak var inspectWindow: NSWindow!
	
	@IBOutlet weak var editKey: NSTextField!
	@IBOutlet weak var editValue: NSText!
	
	private var values = [KeyValuePair]()
	
	private var editRow = -1
	
	@MainActor
	var dictionary: [String : String]! {
		get {
			var dictionary: [String: String] = [:]
			dictionary.reserveCapacity(values.count)
			
			for pair in values {
				dictionary[pair.key] = pair.value
			}
			return dictionary
		}
		set {
			let dict2 = newValue ?? [:]
			values.removeAll()
			values.reserveCapacity(dict2.count)
			
			for (key, value) in dict2 {
				values.append(KeyValuePair(key: key, value: value))
			}
			
			_sortKeys()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	private func index(ofKey aKay: String) -> Int? {
		values.firstIndex(where: { $0.key == aKay })
	}
	
	private func keyExistsAlready(_ aKey: String) -> Bool {
		return index(ofKey: aKey) != nil
	}
	
	@IBAction func addItem(_ sender: Any!) {
		guard _endEditing() else {
			return
		}
		
		tableView.window?.endEditing(for: tableView)
		
		var keyOffset = 2
		let defaultKey = NSLocalizedString("DefaultKey", bundle: Bundle(for: KeyValueDataSource.self), comment: "Default key")
		var key = defaultKey
		
		while keyExistsAlready(key) {
			key = defaultKey + "\(keyOffset)"
			keyOffset += 1
		}
		
		values.append(KeyValuePair(key: key, value: NSLocalizedString("DefaultValue", bundle: Bundle(for: KeyValueDataSource.self), comment: "Default value")))
		
		tableView.reloadData()
		
		tableView.selectRowIndexes(IndexSet(integer: values.count - 1), byExtendingSelection: false)
		tableView.editColumn(0, row: values.count - 1, with: nil, select: true)
		
		NotificationCenter.default.post(name: KeyValueDataSource.changedNotification, object: self)
	}
	
	@IBAction func removeItems(_ sender: Any!) {
		guard _endEditing() else {
			return
		}
		let selectedRows = tableView.selectedRowIndexes
		
		if !selectedRows.isEmpty {
			values.remove(atOffsets: selectedRows)
			
			tableView.reloadData()
			
			NotificationCenter.default.post(name: KeyValueDataSource.changedNotification, object: self)
		}
	}
	
	@IBAction func editItem(_ sender: Any!) {
		guard _endEditing() else {
			return
		}
		tableView.window?.endEditing(for: tableView)
		
		editRow = tableView.selectedRow
		
		if editRow != -1 {
			let data = values[editRow]
			editKey.stringValue = data.key
			editValue.string = data.value
			
			tableView.window?.beginSheet(inspectWindow, completionHandler: { (returnCode) in
				if returnCode == .alertFirstButtonReturn {
					self.values[self.editRow].value = self.editValue.string
				}
				
				self.editRow = -1
				self._sortKeys()
			})
		}
	}
	
	@IBAction func endEditItem(_ sender: NSControl!) {
		tableView.window?.endSheet(inspectWindow, returnCode: sender.tag == 1 ? .alertFirstButtonReturn : .alertSecondButtonReturn)
		inspectWindow.close()
	}
	
	@MainActor
	func _endEditing() -> Bool {
		return tableView?.window?.makeFirstResponder(tableView?.window) ?? false
	}
	
	@objc
	private func _tableViewDidEndEditing(_ notification: Notification) {
		// Once the table is done editing, sort the rows based on the keys
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_sortKeys), object: nil)
		perform(#selector(_sortKeys), with: nil, afterDelay: 0)
	}
	
	@objc @MainActor
	private func _sortKeys() {
		if editRow == -1 && tableView?.editedRow == -1 {
			var selectedKey: String? = nil
			
			if let selectedRow = tableView?.selectedRow, selectedRow != -1 {
				selectedKey = values[selectedRow].key
			}
			
			values.sort(by: { $0.key < $1.key })
			tableView?.reloadData()
			
			if let selectedKey {
				tableView?.selectRowIndexes(IndexSet(integer: index(ofKey: selectedKey)!), byExtendingSelection: false)
			}
		}
	}
	
	// MARK: - NSTable datasource methods

	func numberOfRows(in tableView: NSTableView) -> Int {
		return values.count
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		let data = values[row]
		
		if tableColumn?.identifier == KEY_COLUMN_ID {
			return data.key
		} else {
			return data.value
		}
	}
	
	func tableView(_ tableView: NSTableView, setObjectValue object1: Any?, for tableColumn: NSTableColumn?, row: Int) {
		let object = (object1 as? String) ?? ""
		
		if tableColumn?.identifier == KEY_COLUMN_ID {
			values[row].key = object
		} else {
			values[row].value = object
		}
		
		NotificationCenter.default.post(name: KeyValueDataSource.changedNotification, object: self)
	}
	
	// MARK: - NSControl Delegate methods

	func control(_ control: NSControl, isValidObject: Any?) -> Bool {
		guard let object = isValidObject as? String else {
			return false
		}
		// Check first if we are trying to set the VALUE value
		if tableView.tableColumns[tableView.editedColumn].identifier != KEY_COLUMN_ID {
			if let _ = object.range(of: "$") {
				let defaultsKey = bundleIdentifier + ".NoValueWarning"
				
				if !UserDefaults.standard.bool(forKey: defaultsKey) {
					let ourBundle = Bundle(for: KeyValueDataSource.self)
					let alert = NSAlert()
					alert.messageText = NSLocalizedString("ValueWarning", bundle: ourBundle, comment: "Value warning")
					alert.informativeText = NSLocalizedString("DollarValueWarning", bundle: ourBundle, comment: "Value warning, $ variables aren't expanded")
					alert.addButton(withTitle: NSLocalizedString("Continue", bundle: ourBundle, comment: "Continue label"))
					alert.addButton(withTitle: NSLocalizedString("DontShowAgain", bundle: ourBundle, comment: "Don't show again label"))
					alert.beginSheetModal(for: tableView.window!) { response in
						if response == .alertSecondButtonReturn {
							UserDefaults.standard.set(true, forKey: defaultsKey)
							UserDefaults.standard.synchronize()
						}
					}
				}
			}
		}
		// Must be trying to set the KEY value, but it was empty
		else if object.isEmpty {
			let alert = NSAlert()
			alert.messageText = NSLocalizedString("InvalidKey", bundle: Bundle(for: KeyValueDataSource.self), comment: "Invalid Key")
			alert.informativeText = NSLocalizedString("ZeroLengthKey", bundle: Bundle(for: KeyValueDataSource.self), comment: "Invalid Key, non-zero length")
			alert.beginSheetModal(for: tableView.window!)
			return false
		}
		// If the user entered a new value for the key and the key exists in the data source already
		else if values[tableView.editedRow].key == object, keyExistsAlready(object) {
			let alert = NSAlert()
			alert.messageText = NSLocalizedString("InvalidKey", bundle: Bundle(for: KeyValueDataSource.self), comment: "Invalid Key")
			alert.informativeText = NSLocalizedString("KeyExists", bundle: Bundle(for: KeyValueDataSource.self), comment: "Invalid key, already exists")
			alert.beginSheetModal(for: tableView.window!)
			return false
		}
		// If the key was set to PATH, make sure to complain
		else if object == "PATH" {
			let defaultsKey = bundleIdentifier + ".NoPathWarning"
			
			// Only do it if the user hasn't said they should ignore further warnings on this issue.
			if !UserDefaults.standard.bool(forKey: defaultsKey) {
				let ourBundle = Bundle(for: KeyValueDataSource.self)
				let alert = NSAlert()
				alert.messageText = NSLocalizedString("KeyWarning", bundle: ourBundle, comment: "Key warning")
				alert.informativeText = NSLocalizedString("PathKeyWarning", bundle: ourBundle, comment: "Key warning, PATH variables can be bad")
				alert.addButton(withTitle: NSLocalizedString("Continue", bundle: ourBundle, comment: "Continue label"))
				alert.addButton(withTitle: NSLocalizedString("DontShowAgain", bundle: ourBundle, comment: "Don't show again label"))
				alert.beginSheetModal(for: tableView.window!) { response in
					if response == .alertSecondButtonReturn {
						UserDefaults.standard.set(true, forKey: defaultsKey)
						UserDefaults.standard.synchronize()
					}
				}
			}
		}
		
		return true
	}
}

//
//  ViewController.swift
//  Auditor
//
//  Created by Lance Jabr on 6/21/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var audioEngine = AudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        AudioRoute.onDevicesChanged = {
            self.audioEngine = AudioEngine()
            self.inputTable.reloadData()
            self.outputTable.reloadData()
            self.setTableSelection()
        }
        
        setTableSelection()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBOutlet var inputTable: NSTableView!
    @IBOutlet var outputTable: NSTableView!

    fileprivate func setTableSelection() {
        let inputI = AudioRoute.availableInputs.index(of: AudioRoute.currentInput)
        inputTable.selectRowIndexes(IndexSet(integer: inputI!), byExtendingSelection: false)
        
        let outputI = AudioRoute.availableOutputs.index(of: AudioRoute.currentOutput)
        outputTable.selectRowIndexes(IndexSet(integer: outputI!), byExtendingSelection: false)
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        var table = tableView === inputTable ? AudioRoute.availableInputs : AudioRoute.availableOutputs
        table = table.filter({!$0.name.hasPrefix("CA") && !$0.name.hasPrefix("Instant")})
        return table.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        var table = tableView === inputTable ? AudioRoute.availableInputs : AudioRoute.availableOutputs
        table = table.filter({!$0.name.hasPrefix("CA") && !$0.name.hasPrefix("Instant")})
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("MyView"), owner: self) as! NSTableCellView
        cell.textField!.stringValue = table[row].name
        return cell
    }
    
    func tableViewSelectionDidChange(_ aNotification: Notification) {
        let tableView: NSTableView = aNotification.object as! NSTableView
        let row = tableView.selectedRow
        if row < 0 { setTableSelection(); return }
        var table = tableView === inputTable ? AudioRoute.availableInputs : AudioRoute.availableOutputs
        table = table.filter({!$0.name.hasPrefix("CA") && !$0.name.hasPrefix("Instant")})

        if tableView === inputTable {
            AudioRoute.currentInput = table[row]
        }
        
        if tableView === outputTable {
            AudioRoute.currentOutput = table[row]
        }
        
//        if row > 0 {
//            component = playEngine.availableAudioUnits[row-1]
//            showCustomViewButton.isEnabled = true
//        } else {
//            component = nil
//            showCustomViewButton.isEnabled = false
//        }
        
//        if tableView === effectTable {
//            self.closeAUView()
//            let row = tableView.selectedRow
//            let component: AVAudioUnitComponent?
//
//            if row > 0 {
//                component = playEngine.availableAudioUnits[row-1]
//                showCustomViewButton.isEnabled = true
//            } else {
//                component = nil
//                showCustomViewButton.isEnabled = false
//            }
//
//            playEngine.selectAudioUnitComponent(component, completionHandler: {})
//        }
    }
}

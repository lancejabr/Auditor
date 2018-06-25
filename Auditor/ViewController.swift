//
//  ViewController.swift
//  Auditor
//
//  Created by Lance Jabr on 6/21/18.
//  Copyright © 2018 Lance Jabr. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let audioEngine = AudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Swift.print(AudioRoute.availableDevices)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBOutlet var inputTable: NSTableView!
    @IBOutlet var outputTable: NSTableView!

}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tableView === inputTable ? AudioRoute.availableInputs.count : AudioRoute.availableOutputs.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let devices = tableView === inputTable ? AudioRoute.availableInputs : AudioRoute.availableOutputs
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("MyView"), owner: self) as! NSTableCellView
        cell.textField!.stringValue = devices[row].name
        return cell
    }
    
    func tableViewSelectionDidChange(_ aNotification: Notification) {
        let tableView: NSTableView = aNotification.object as! NSTableView
        let row = tableView.selectedRow
        
        if row > 0 {
            component = playEngine.availableAudioUnits[row-1]
            showCustomViewButton.isEnabled = true
        } else {
            component = nil
            showCustomViewButton.isEnabled = false
        }
        
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

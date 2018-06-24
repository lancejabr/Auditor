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
        
        // Do any additional setup after loading the view.
//        let audioEngine = AudioEngine()
        
    
        
        Swift.print("in: ", AudioRoute.currentInput)
        Swift.print(AudioRoute.availableInputs)
        Swift.print("out: ", AudioRoute.currentOutput)
        Swift.print(AudioRoute.availableOutputs)
        
        Swift.print(AudioRoute.availableDevices)

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}


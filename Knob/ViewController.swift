//
//  ViewController.swift
//  Knob
//
//  Created by Chris Gulley on 9/15/15.
//  Copyright © 2015 Chris Gulley. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var knob: Knob!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func knobRotated(sender: Knob) {
        print("value: \(knob.value)")
    }
}


//
//  SettingsViewController.swift
//  Commotion
//
//  Created by Haya Alhumaid on 10/11/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    //MARK:- Interface Builder
    @IBOutlet weak var stepTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!

    //MARK:- ViewController's Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //MARK:- Methods
    
}

//MARK:- Buttons Actions
extension SettingsViewController {
    @IBAction func saveButtonPressed() {
        if stepTextField.text != "" {
            let steps = Int(stepTextField.text!)!
            UserDefaults.standard.set(steps, forKey: "StepGoal")
            self.navigationController?.popViewController(animated: true)
        }
    }
}

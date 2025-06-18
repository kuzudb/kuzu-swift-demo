//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Kuzu
import UIKit

class SetupViewController: UIViewController {
    @IBOutlet weak var bmSizeTextField: UITextField!
    @IBOutlet weak var threadsTextField: UITextField!

    override func viewDidLoad() {

        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addDoneButtonOnKeyboard()
        loadMsMarcoButton.isEnabled = false
        loadLdbcButton.isEnabled = false
        loadLastFmButton.isEnabled = false
        loadMnistButton.isEnabled = false
        runFtsButton.isEnabled = false
        runLdbcButton.isEnabled = false
        runLastFmButton.isEnabled = false
        runMnistButton.isEnabled = false
    }

    func getResultViewController() -> ResultViewController? {
        if let tabBarController = self.tabBarController,
            let viewControllers = tabBarController.viewControllers,
            let resultVc = viewControllers[2] as? ResultViewController
        {
            _ = resultVc.view
            return resultVc
        }
        return nil
    }
    
    @IBOutlet weak var loadMsMarcoButton: UIButton!
    @IBOutlet weak var loadLdbcButton: UIButton!
    @IBOutlet weak var loadLastFmButton: UIButton!
    @IBOutlet weak var loadMnistButton: UIButton!
    @IBOutlet weak var runFtsButton: UIButton!
    @IBOutlet weak var runLdbcButton: UIButton!
    @IBOutlet weak var runLastFmButton: UIButton!
    @IBOutlet weak var runMnistButton: UIButton!

    
    @IBAction func initKuzuClicked(_ sender: Any) {
        let bmSize = Int(bmSizeTextField.text!)! * 1024 * 1024
        let numThreads = Int(threadsTextField.text!)!
        let resultVc = self.getResultViewController()!
        resultVc.initKuzu(bmSize: bmSize, numThreads: numThreads)
        loadMsMarcoButton.isEnabled = true
        loadLdbcButton.isEnabled = true
        loadLastFmButton.isEnabled = true
        loadMnistButton.isEnabled = true
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    @IBAction func loadMsMarcoClicked(_ sender: Any) {
        let resultVc = self.getResultViewController()!
        try! resultVc.loadMsMarco()
        runFtsButton.isEnabled = true
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    @IBAction func loadLdbcClicked(_ sender: Any) {
        let resultVc = self.getResultViewController()
        try! resultVc?.loadLdbc()
        runLdbcButton.isEnabled = true
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    @IBAction func loadLastFmClicked(_ sender: Any) {
        let resultVc = self.getResultViewController()
        try! resultVc?.loadLastFm()
        runLastFmButton.isEnabled = true
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    @IBAction func loadMnistClicked(_ sender: Any) {
        let resultVc = self.getResultViewController()
        try! resultVc?.loadMnist()
        runMnistButton.isEnabled = true
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    @IBAction func runFtsClicked(_ sender: Any) {
        let resultVc = self.getResultViewController()!
        try! resultVc.runFts()
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    @IBAction func runLdbcClicked(_ sender: Any) {
        let resultVc = self.getResultViewController()!
        try! resultVc.runLdbc()
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    @IBAction func runLastFmClicked(_ sender: Any) {
        let resultVc = self.getResultViewController()!
        try! resultVc.runLastFm()
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    @IBAction func runMnistClicked(_ sender: Any) {
        let resultVc = self.getResultViewController()!
        try! resultVc.runMnist()
        if let tabBarController = self.tabBarController{
            tabBarController.selectedViewController = resultVc
        }
    }

    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(
            frame: CGRect.init(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 50
            )
        )
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        let done: UIBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(self.doneButtonAction)
        )

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        bmSizeTextField.inputAccessoryView = doneToolbar
        threadsTextField.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction() {
        bmSizeTextField.resignFirstResponder()
        threadsTextField.resignFirstResponder()
    }
}

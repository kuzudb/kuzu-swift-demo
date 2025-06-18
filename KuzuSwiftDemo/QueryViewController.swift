//
//  kuzu-swift-demo
//  https://github.com/kuzudb/kuzu-swift-demo
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Kuzu
import UIKit

class QueryViewController: UIViewController {

    override func viewDidLoad() {

        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.addDoneButtonOnKeyboard()
    }

    @IBOutlet weak var queryTextArea: UITextView!

    @IBAction func clearButtonClicked(_ sender: Any) {
        queryTextArea.text = ""
    }

    @IBAction func runButtonClicked(_ sender: Any) {
        let queryString = queryTextArea.text!
        if let tabBarController = self.tabBarController,
            let viewControllers = tabBarController.viewControllers,
            let resultVc = viewControllers[2] as? ResultViewController
        {
            try! resultVc.executeQuery(query: queryString)
            if let tabBarController = self.tabBarController {
                tabBarController.selectedViewController = resultVc
            }
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

        queryTextArea.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction() {
        queryTextArea.resignFirstResponder()
    }

}

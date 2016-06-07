//
//  HInfoViewController.swift
//  Stellar Hedron
//
//  Created by David S Reich on 28/10/2015.
//  Copyright © 2015 Stellar Software Pty Ltd. All rights reserved.
//

import UIKit

class HInfoViewController: UIViewController {

    @IBOutlet weak var okContainerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        okContainerView.layer.borderColor = UIColor.blackColor().CGColor
        okContainerView.layer.borderWidth = 2
        okContainerView.layer.cornerRadius = 10
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func okButtonTouched(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

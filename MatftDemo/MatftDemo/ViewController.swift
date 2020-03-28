//
//  ViewController.swift
//  MatftDemo
//
//  Created by AM19A0 on 2020/03/20.
//  Copyright © 2020 jkado. All rights reserved.
//

import UIKit
import Matft

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let a = MfArray([[2, 1, -3, 0],
                         [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
        let b = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                         [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)
        let c = a*b
        print(c)
    }


}


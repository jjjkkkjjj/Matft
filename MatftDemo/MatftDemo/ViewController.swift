//
//  ViewController.swift
//  MatftDemo
//
//  Created by AM19A0 on 2020/03/20.
//  Copyright © 2020 jkado. All rights reserved.
//

import UIKit
import Matft
import Accelerate
import CoreGraphics

class ViewController: UIViewController {

    @IBOutlet weak var originalImageView: UIImageView!
    @IBOutlet weak var reverseImageView: UIImageView!
    @IBOutlet weak var swapImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.originalImageView.image = UIImage(named: "rena.jpeg")
        self.reverseImageView.image = UIImage(named: "rena.jpeg")
        self.swapImageView.image = UIImage(named: "rena.jpeg")

        self.reverse()
        self.swapchannel()
    }
    
    func reverse(){
        var image = Matft.image.cgimage2mfarray(self.reverseImageView.image!.cgImage!)

        // reverse
        image = image[~<<-1]
        self.reverseImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
    }
    
    
    func swapchannel(){
        var image = Matft.image.cgimage2mfarray(self.swapImageView.image!.cgImage!)

        // swap channel
        //image = image[0~<, 0~<, MfArray([1,0,2,3])] // not supported
        image = image.swapaxes(axis1: 0, axis2: -1)[MfArray([1,0,2,3])].swapaxes(axis1: 0, axis2: -1)
        self.swapImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
    }
}


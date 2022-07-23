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
import CoreGraphics.CGBitmapContext

class ViewController: UIViewController {

    @IBOutlet weak var originalImageView: UIImageView!
    @IBOutlet weak var reverseImageView: UIImageView!
    @IBOutlet weak var grayreverseImageView: UIImageView!
    @IBOutlet weak var swapImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.originalImageView.image = UIImage(named: "rena.jpeg")
        self.reverseImageView.image = UIImage(named: "rena.jpeg")
        self.grayreverseImageView.image = self.convertToGrayScale(image: UIImage(named: "rena.jpeg")!)
        self.swapImageView.image = UIImage(named: "rena.jpeg")

        self.reverse()
        self.grayreverse()
        self.swapchannel()
        self.resize()
    }
    
    func reverse(){
        var image = Matft.image.cgimage2mfarray(self.reverseImageView.image!.cgImage!)

        // reverse
        image = image[Matft.reverse] // same as image[~<<-1]
        self.reverseImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
    }
    
    
    func swapchannel(){
        var image = Matft.image.cgimage2mfarray(self.swapImageView.image!.cgImage!)

        // swap channel
        image = image[Matft.all, Matft.all, MfArray([1,0,2,3])] // same as image[0~<, 0~<, MfArray([1,0,2,3])]
        self.swapImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
    }
    
    func grayreverse(){
        var image = Matft.image.cgimage2mfarray(self.grayreverseImageView.image!.cgImage!, mftype: .UInt8)
        
        // reverse
        image = image[Matft.reverse] // same as image[~<<-1]

        self.grayreverseImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
    }
    
    func convertToGrayScale(image: UIImage) -> UIImage{
        //let gray_mfarray = (Matft.image.toGray(Matft.image.cgimage2mfarray(image.cgImage!)) * Float(255)).astype(.UInt8)
        let gray_mfarray = Matft.image.toGray(Matft.image.cgimage2mfarray(image.cgImage!))
        return UIImage(cgImage: Matft.image.mfarray2cgimage(gray_mfarray))
    }
    
    func resize(){
        var image = Matft.image.cgimage2mfarray(self.swapImageView.image!.cgImage!)

        // resize
        image = Matft.image.resize(image, width: 300, height: 300)
        self.swapImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
        //self.swapImageView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
    }
    
}


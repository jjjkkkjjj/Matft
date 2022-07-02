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
    @IBOutlet weak var grayreverseImageView: UIImageView!
    @IBOutlet weak var swapImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.originalImageView.image = UIImage(named: "rena.jpeg")
        self.reverseImageView.image = UIImage(named: "rena.jpeg")
        self.grayreverseImageView.image = self.convertToGrayScale(image: UIImage(named: "rena.jpeg")!)
        self.swapImageView.image = UIImage(named: "rena.jpeg")

        self.reverse()
        //self.grayreverse()
        self.swapchannel()
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
        var image = Matft.image.cgimage2mfarray(self.grayreverseImageView.image!.cgImage!)

        // reverse
        image = image[Matft.reverse] // same as image[~<<-1]
        print(image[image === 0])
        self.grayreverseImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
    }
    
    // ref: https://stackoverflow.com/questions/43040333/convert-uiimage-colored-to-grayscale-using-cgcolorspacecreatedevicegray
    func convertToGrayScale(image: UIImage) -> UIImage {
        let imageRect:CGRect = CGRect(x:0, y:0, width:image.size.width, height: image.size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let channel = Int(image.cgImage!.bitsPerPixel/8)

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        //have to draw before create image

        context?.draw(image.cgImage!, in: imageRect)
        let imageRef = context!.makeImage()
        let newImage = UIImage(cgImage: imageRef!)
        /*
        var arr = Array<UInt8>(repeating: UInt8.zero, count: width*height)
        let newdata = MfData(size: width*height, mftype: .UInt8)
        newdata.withUnsafeMutableStartPointer(datatype: Float.self){
            let srcptr = CFDataGetBytePtr(newImage.cgImage!.dataProvider!.data)!
            vDSP_vfltu8(srcptr, vDSP_Stride(1), $0, vDSP_Stride(1), vDSP_Length(width*height))
        }
        
        let newstructure = MfStructure(shape: [height, width], mforder: .Row)
        var image = MfArray(mfdata: newdata, mfstructure: newstructure).squeeze()
        image = image[Matft.reverse]
        */
        /*
        let unusedCallback: CGDataProviderReleaseDataCallback = { optionalPointer, pointer, valueInt in }
        let provider = CGDataProvider(dataInfo: nil, data: context!.data!, size: width*height, releaseData: unusedCallback)!
        //let provider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, CFDataGetBytePtr(newImage.cgImage!.dataProvider!.data)!, width*height))!
        return UIImage(cgImage: CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!)
         */
        //return UIImage(cgImage: Matft.image.mfarray2cgimage(image))
        //return newImage
    }
}


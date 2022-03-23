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
    @IBOutlet weak var processedImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.originalImageView.image = UIImage(named: "rena.jpeg")
        self.processedImageView.image = UIImage(named: "rena.jpeg")

        self.reverse()
    }
    
    func reverse(){
        let size = CFDataGetLength(self.processedImageView.image!.cgImage!.dataProvider!.data)
        let width = Int(self.processedImageView.image!.size.width)
        let height = Int(self.processedImageView.image!.size.height)
        
        var arr = Matft.nums(Float.zero, shape: [height, width, 4])
        var dst = Array<UInt8>(repeating: UInt8.zero, count: arr.size)
        
        arr.withDataUnsafeMBPtrT(datatype: Float.self){
        
            let srcptr = CFDataGetBytePtr(self.processedImageView.image?.cgImage?.dataProvider?.data)!
            
            // unit8 to float
            vDSP_vfltu8(srcptr, vDSP_Stride(1), $0.baseAddress!, vDSP_Stride(1), vDSP_Length(size))
        }

        // reverse
        arr = arr[~<<-1]
        arr = arr.conv_order(mforder: .Row)
        
        arr.withDataUnsafeMBPtrT(datatype: Float.self){
            srcptr in
            
            dst.withUnsafeMutableBufferPointer{
                // float to unit8
                vDSP_vfixu8(srcptr.baseAddress!, vDSP_Stride(1), $0.baseAddress!, vDSP_Stride(1), vDSP_Length(arr.size))
                
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
                let provider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, $0.baseAddress!, arr.size))
                let cgimage =  CGImage(width: arr.shape[1], height: arr.shape[0], bitsPerComponent: 8*1, bitsPerPixel: 8*arr.shape[2], bytesPerRow: arr.shape[1]*arr.shape[2], space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)
                
                self.processedImageView.image = UIImage(cgImage: cgimage!)
            }
            
        }
         
    }
    
    /*
    func swapchannel(){
        let size = CFDataGetLength(self.processedImageView.image!.cgImage!.dataProvider!.data)
        let width = Int(self.processedImageView.image!.size.width)
        let height = Int(self.processedImageView.image!.size.height)
        
        var arr = Matft.nums(Float.zero, shape: [height, width, 4])
        var dst = Array<UInt8>(repeating: UInt8.zero, count: arr.size)
        
        arr.withDataUnsafeMBPtrT(datatype: Float.self){
        
            let srcptr = CFDataGetBytePtr(self.processedImageView.image?.cgImage?.dataProvider?.data)!
            
            // unit8 to float
            vDSP_vfltu8(srcptr, vDSP_Stride(1), $0.baseAddress!, vDSP_Stride(1), vDSP_Length(size))
        }

        // reverse
        arr = arr[0~<, 0~<, ~<<-1]
        arr = arr.conv_order(mforder: .Row)
        
        arr.withDataUnsafeMBPtrT(datatype: Float.self){
            srcptr in
            
            dst.withUnsafeMutableBufferPointer{
                // float to unit8
                vDSP_vfixu8(srcptr.baseAddress!, vDSP_Stride(1), $0.baseAddress!, vDSP_Stride(1), vDSP_Length(arr.size))
                
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
                let provider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, $0.baseAddress!, arr.size))
                let cgimage =  CGImage(width: arr.shape[1], height: arr.shape[0], bitsPerComponent: 8*1, bitsPerPixel: 8*arr.shape[2], bytesPerRow: arr.shape[1]*arr.shape[2], space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)
                
                self.processedImageView.image = UIImage(cgImage: cgimage!)
            }
            
        }
         
    }*/
}


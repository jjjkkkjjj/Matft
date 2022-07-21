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
        //self.grayreverseImageView.image = UIImage(named: "rena.jpeg")
        self.swapImageView.image = UIImage(named: "rena.jpeg")

        self.reverse()
        self.grayreverse()
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
        //var image = self.toFMfArray(image: self.grayreverseImageView.image!)
        var image = Matft.image.cgimage2mfarray(self.grayreverseImageView.image!.cgImage!)
        
        // reverse
        image = image[Matft.reverse] // same as image[~<<-1]
        print(image)
        //self.grayreverseImageView.image = self.toFUIImage(mfarray: image)
        self.grayreverseImageView.image = UIImage(cgImage: Matft.image.mfarray2cgimage(image))
    }
    
    func convertToGrayScale(image: UIImage) -> UIImage{
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let channel = Int(image.cgImage!.bitsPerPixel/8)
        
        let imageRect: CGRect = CGRect(x:0, y:0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        context?.draw(image.cgImage!, in: imageRect)
        let imageRef = context!.makeImage()
        let newImage = UIImage(cgImage: imageRef!)
        return newImage
    }
    
    // ref: https://stackoverflow.com/questions/43040333/convert-uiimage-colored-to-grayscale-using-cgcolorspacecreatedevicegray
    func toMfArray(image: UIImage) -> MfArray {
        let cgimage = image.cgImage!
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let channel = Int(cgimage.bitsPerPixel/8)

        //====== cgimage to tmp UInt8 array ======//
        // ref: https://github.com/opencv/opencv/blob/ed69bcae2d171d9426cd3688a8b0ee14b8a140cd/modules/imgcodecs/src/apple_conversions.mm#L47
        let colorModel: CGColorSpaceModel = cgimage.colorSpace!.model
        let bitmapInfo: CGBitmapInfo
        let colorSpace: CGColorSpace
        let size = width*height*channel
        if (colorModel == CGColorSpaceModel.monochrome){
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
            colorSpace = CGColorSpaceCreateDeviceGray()
        }
        else if (colorModel == CGColorSpaceModel.indexed){
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
            colorSpace = CGColorSpaceCreateDeviceRGB()
        }
        else{
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
            colorSpace = cgimage.colorSpace!
        }
        
        var arr = Array<UInt8>(repeating: UInt8.zero, count: size)
        arr.withUnsafeMutableBytes{
            let contextRef = CGContext(data: $0.baseAddress!, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*channel, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
            contextRef?.draw(cgimage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        //====== tmp UInt8 array to newdata ======//
        let newdata = MfData(size: size, mftype: .UInt8)
        newdata.withUnsafeMutableStartPointer(datatype: Float.self){
            dstptr in
            arr.withUnsafeBufferPointer{
                vDSP_vfltu8($0.baseAddress!, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(size))
            }
        }
        
        let newstructure = MfStructure(shape: [height, width], mforder: .Row)
        return MfArray(mfdata: newdata, mfstructure: newstructure).squeeze()
        
    }
    
    func toFMfArray(image: UIImage) -> MfArray{
        let cgimage = image.cgImage!
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let channel = Int(cgimage.bitsPerPixel/8)

        //====== cgimage to tmp UInt8 array ======//
        // ref: https://github.com/opencv/opencv/blob/ed69bcae2d171d9426cd3688a8b0ee14b8a140cd/modules/imgcodecs/src/apple_conversions.mm#L47
        let colorModel: CGColorSpaceModel = cgimage.colorSpace!.model
        let bitmapInfo: CGBitmapInfo
        let colorSpace: CGColorSpace
        let size = width*height*channel
        if (colorModel == CGColorSpaceModel.monochrome){
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.order32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
            colorSpace = CGColorSpaceCreateDeviceGray()
        }
        else if (colorModel == CGColorSpaceModel.indexed){
            //bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
            colorSpace = CGColorSpaceCreateDeviceRGB()
        }
        else{
            //bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
            colorSpace = cgimage.colorSpace!
        }

        var arr = Array<Float>(repeating: Float.zero, count: size)
        arr.withUnsafeMutableBytes{
            let contextRef = CGContext(data: $0.baseAddress!, width: width, height: height, bitsPerComponent: 32, bytesPerRow: width*channel*4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
            contextRef?.draw(cgimage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        //====== tmp Float array to newdata ======//
        let newdata = MfData(size: size, mftype: .Float)
        newdata.withUnsafeMutableStartPointer(datatype: Float.self){
            dstptr in
            arr.withUnsafeBufferPointer{
                memcpy(dstptr, $0.baseAddress!, size*4)
            }
        }
        
        let newstructure = MfStructure(shape: [height, width, channel], mforder: .Row)
        return MfArray(mfdata: newdata, mfstructure: newstructure).squeeze()
    }
    
    func toUIImage(mfarray: MfArray) -> UIImage{
        var mfarray = mfarray
        if mfarray.ndim == 2{
            mfarray = mfarray.expand_dims(axis: 2)
        }
        mfarray = mfarray.to_contiguous(mforder: .Row)
        
        //====== MfArray to cgimage ======//
        var dst = Array<UInt8>(repeating: UInt8.zero, count: mfarray.size)
        let dst_strides = mfarray.strides
        let height = mfarray.shape[0]
        let width = mfarray.shape[1]
        let channel = mfarray.shape[2]
        
        let colorSpace: CGColorSpace
        let bitmapInfo: CGBitmapInfo
        if channel == 1{
            colorSpace = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
        }
        else{
            colorSpace = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGImageByteOrderInfo.orderDefault.rawValue)
        }
        
        // StoredType to UInt8
        dst.withUnsafeMutableBufferPointer{
            dstptrU in
            mfarray.withUnsafeMutableStartPointer(datatype: Float.self){
                [unowned mfarray] srcptrT in
                vDSP_vfixru8(srcptrT, vDSP_Stride(1), dstptrU.baseAddress!, vDSP_Stride(1), vDSP_Length(mfarray.size))
                
            }
        }
        
        let cgimage = dst.withUnsafeMutableBufferPointer{
            (ptr) -> CGImage in
            let provider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, ptr.baseAddress!, mfarray.size))
            let cgimage =  CGImage(width: width, height: height, bitsPerComponent: 8*1, bitsPerPixel: 8*1, bytesPerRow: dst_strides[0], space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
            
            return cgimage
        }
        return UIImage(cgImage: cgimage)
    }
    
    func toFUIImage(mfarray: MfArray) -> UIImage{
        var mfarray = mfarray
        if mfarray.ndim == 2{
            mfarray = mfarray.expand_dims(axis: 2)
        }
        mfarray = mfarray.to_contiguous(mforder: .Row)
        
        //====== MfArray to cgimage ======//
        let dst_strides = mfarray.strides
        let height = mfarray.shape[0]
        let width = mfarray.shape[1]
        let channel = mfarray.shape[2]
        
        let colorSpace: CGColorSpace
        let bitmapInfo: CGBitmapInfo
        if channel == 1{
            colorSpace = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.order32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
        }
        else{
            colorSpace = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
        }
        
        let cgimage = mfarray.withUnsafeMutableStartRawPointer{
            (ptr) -> CGImage in
            let provider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, ptr.assumingMemoryBound(to: UInt8.self), mfarray.size*4))
            let cgimage =  CGImage(width: width, height: height, bitsPerComponent: 8*4, bitsPerPixel: 8*channel*4, bytesPerRow: dst_strides[0]*4, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
            
            return cgimage
        }
        
        return UIImage(cgImage: cgimage)
    }
}


import UIKit
import Matft
import Accelerate

let rgb = UIImage(named: "rena.jpeg")!

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

let gray = convertToGrayScale(image: rgb)


var mf_rgb = Matft.image.cgimage2mfarray(rgb.cgImage!)
var mf_gray = Matft.image.cgimage2mfarray(gray.cgImage!)


mf_rgb = mf_rgb[Matft.reverse].to_contiguous(mforder: .Row)
mf_gray = mf_gray[Matft.reverse]

Matft.image.mfarray2cgimage(mf_rgb)
Matft.image.mfarray2cgimage(mf_gray)

/*********
    Row Contiguous
*/
/*
// resize
// ref: https://developer.apple.com/documentation/accelerate/1509208-vimagescale_argbffff
let newdata = MfData(size: 150*150*4, mftype: .Float)
let newstructure = MfStructure(shape: [150, 150, 4], mforder: .Row)
newdata.withUnsafeMutableStartRawPointer{
    dstptr in
    mf_rgb.withUnsafeMutableStartRawPointer{
        srcptr in
        var src_buffer = vImage_Buffer(data: srcptr, height: vImagePixelCount(225), width: vImagePixelCount(225), rowBytes: 225*4*4)
        var dst_buffer = vImage_Buffer(data: dstptr, height: vImagePixelCount(150), width: vImagePixelCount(150), rowBytes: 150*4*4)
        
        vImageScale_ARGBFFFF(&src_buffer, &dst_buffer, nil, vImage_Flags(kvImageHighQualityResampling))
    }

}

let resize = MfArray(mfdata: newdata, mfstructure: newstructure)
print(resize)
Matft.image.mfarray2cgimage(resize)
*/

/*********
    Column Contiguous
*/
mf_rgb = mf_rgb.to_contiguous(mforder: .Column)

// resize
// ref: https://developer.apple.com/documentation/accelerate/1509208-vimagescale_argbffff
let newdata = MfData(size: 150*150*4, mftype: .Float)
let newstructure = MfStructure(shape: [150, 150, 4], mforder: .Column)
newdata.withUnsafeMutableStartRawPointer{
    dstptr in
    mf_rgb.withUnsafeMutableStartRawPointer{
        srcptr in
        for i in 0..<4{
            var src_buffer = vImage_Buffer(data: srcptr + i*225*225*4, height: vImagePixelCount(225), width: vImagePixelCount(225), rowBytes: 225*4)
            var dst_buffer = vImage_Buffer(data: dstptr + i*150*150*4, height: vImagePixelCount(150), width: vImagePixelCount(150), rowBytes: 150*4)
            
            vImageScale_PlanarF(&src_buffer, &dst_buffer, nil, vImage_Flags(kvImageHighQualityResampling))
        }
        
    }

}

var resize = MfArray(mfdata: newdata, mfstructure: newstructure)
Matft.image.mfarray2cgimage(resize)

resize.swapaxes(axis1: -1, axis2: 0)[3] = MfArray([0.5] as [Float])
print(resize)
let alpha = resize[Matft.all, Matft.all, 3~<4]
resize[0~<, 0~<, 0~<3] = (resize[Matft.all, Matft.all, 0~<3]*alpha + (1 - alpha) * MfArray([1, 1, 1], mftype: resize.mftype))
print(resize)



let grayed = Matft.image.color(resize, exclude_alpha: false)
Matft.image.mfarray2cgimage(grayed)


/*
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGImageByteOrderInfo.order32Little.rawValue | CGBitmapInfo.floatComponents.rawValue)
print(resize.strides)
resize.withUnsafeMutableStartRawPointer{
    srcptr -> CGImage in
    // NOTE: Force cast to UInt8
    let provider = CGDataProvider(data: CFDataCreate(kCFAllocatorDefault, srcptr.assumingMemoryBound(to: UInt8.self), 150*150*4*4))
    let cgimage =  CGImage(width: 150, height: 150, bitsPerComponent: 8*4, bitsPerPixel: 8*4*150*150, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
    
    return cgimage
}

*/



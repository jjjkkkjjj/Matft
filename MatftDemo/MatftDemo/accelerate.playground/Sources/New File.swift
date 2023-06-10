import UIKit
import Matft
import Accelerate
/*
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


*/

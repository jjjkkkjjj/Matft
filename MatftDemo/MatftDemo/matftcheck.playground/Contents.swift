import UIKit
import Matft
import Accelerate

let uiimage = UIImage(named: "rena.jpeg")!

// CGImage to MfArray
let rgb = Matft.image.cgimage2mfarray(uiimage.cgImage!)

// Convert RGBA into Gray Image
let gray = Matft.image.toGray(rgb)

// Resize
let rgb_resize = Matft.image.resize(rgb, width: 150, height: 150)
let gray_resize = Matft.image.resize(gray, width: 300, height: 300)

// MfArray to CGImage
Matft.image.mfarray2cgimage(rgb_resize)
Matft.image.mfarray2cgimage(gray_resize)

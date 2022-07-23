import UIKit
import Matft
import Accelerate

let uiimage = UIImage(named: "rena.jpeg")!

/*******************
    resize
 */

// CGImage to MfArray
let rgb = Matft.image.cgimage2mfarray(uiimage.cgImage!)

// Convert RGBA into Gray Image
let gray = Matft.image.color(rgb)

// Resize
let rgb_resize = Matft.image.resize(rgb, width: 150, height: 150)
let gray_resize = Matft.image.resize(gray, width: 300, height: 300)

// MfArray to CGImage
Matft.image.mfarray2cgimage(rgb_resize)
Matft.image.mfarray2cgimage(gray_resize)


/*******************
    afiine
 */

let rbg_rotated = Matft.image.warpAffine(rgb_resize, matrix: MfArray([[0, 1, 1],
                                                                      [1, 0, 0]] as [[Float]]), width: 150, height: 150)
let gray_rotated = Matft.image.warpAffine(gray_resize, matrix: MfArray([[0, 1, 1],
                                                                        [1, 0, 0]] as [[Float]]), width: 150, height: 150)

Matft.image.mfarray2cgimage(rbg_rotated)
Matft.image.mfarray2cgimage(gray_rotated)

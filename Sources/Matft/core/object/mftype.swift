//
//  mftype.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation
#if canImport(CoreML)
import CoreML
#endif

/// The element type of an `MfArray`, the counterpart of Numpy's `dtype`.
///
/// Internally every type except `.Double` is stored as `Float`, and `.Double` is stored as `Double`
/// (see `StoredType`). Therefore integer values whose magnitude exceeds 2^24 may lose precision
/// unless `.Double` is used.
/// Complex arrays keep the logical real type (e.g. `.Float`) and hold a separate imaginary buffer;
/// check `MfArray.isComplex` instead of the `Complex*` cases.
public enum MfType: Int{
    /// No type. Not supported as an array type.
    case None
    /// Boolean.
    case Bool
    /// 8-bit unsigned integer.
    case UInt8
    /// 16-bit unsigned integer.
    case UInt16
    /// 32-bit unsigned integer.
    case UInt32
    /// 64-bit unsigned integer.
    case UInt64
    /// Platform-width unsigned integer.
    case UInt
    /// 8-bit signed integer.
    case Int8
    /// 16-bit signed integer.
    case Int16
    /// 32-bit signed integer.
    case Int32
    /// 64-bit signed integer.
    case Int64
    /// Platform-width signed integer.
    case Int
    /// 32-bit floating point.
    case Float
    /// 64-bit floating point.
    case Double
    /// Complex number of 32-bit floats. Reserved.
    case ComplexFloat
    /// Complex number of 64-bit floats. Reserved.
    case ComplexDouble
    /// Arbitrary object. Not supported as an array type.
    case Object
    
    static internal func mftype(value: Any) -> MfType{
        switch value{
        case is Bool:
            return .Bool
        case is UInt8:
            return .UInt8
        case is UInt16:
            return .UInt16
        case is UInt32:
            return .UInt32
        case is UInt64:
            return .UInt64
        case is UInt:
            return .UInt
        case is Int8:
            return .Int8
        case is Int16:
            return .Int16
        case is Int32:
            return .Int32
        case is Int64:
            return .Int64
        case is Int:
            return .Int
        case is Float:
            return .Float
        case is Double:
            return .Double
        default:
            return .Object
        }
    }
    static internal func mftype<T: MfStorable>(value: T) -> MfType{
        return MfType.mftype(value: value as Any)
    }
    
    #if canImport(CoreML)
    @available(macOS 10.13, *)
    @available(iOS 14.0, *)
    static internal func mftype(value: MLMultiArrayDataType) -> MfType{
        switch value {
        case .double:
            return .Double
        case .float:
            return .Float
        default:
            return .Object // Not supported
        }
    }
    #endif
    
    /// Returns the type with the higher priority, used to decide the result type of a binary operation.
    ///
    /// The priority follows the declaration order (`Bool` < `UInt8` < ... < `Int` < `Float` < `Double`).
    /// - Parameters:
    ///   - a: The first type.
    ///   - b: The second type.
    /// - Returns: The type with the larger raw value.
    static public func priority(_ a: MfType, _ b: MfType) -> MfType{
        if a.rawValue < b.rawValue{
            return b
        }
        else{
            return a
        }
    }
    
    /// The result type of a binary operation between two arrays like `np.result_type`.
    /// Integers are promoted by numpy's rules (e.g. UInt8 and Int8 -> Int16, UInt64 and a signed integer -> Double).
    /// The others follow `priority`, i.e. integers don't get wider by Float because they are stored as Float
    static public func result_type(_ a: MfType, _ b: MfType) -> MfType{
        guard let (au, aw) = a._integerKind, let (bu, bw) = b._integerKind, au != bu else{
            return priority(a, b)
        }
        // mixed signedness
        let (uw, sw) = au ? (aw, bw) : (bw, aw)
        if uw == 64{
            return .Double
        }
        let signed = au ? b : a
        if sw > uw{
            return signed
        }
        switch uw * 2{
        case 16:
            return .Int16
        case 32:
            return .Int32
        default:
            return .Int64
        }
    }

    /// (unsigned, bit width) of an integer type. nil for the others
    private var _integerKind: (unsigned: Bool, width: Int)?{
        switch self{
        case .UInt8: return (true, 8)
        case .UInt16: return (true, 16)
        case .UInt32: return (true, 32)
        case .UInt64: return (true, 64)
        case .UInt: return (true, Swift.Int.bitWidth)
        case .Int8: return (false, 8)
        case .Int16: return (false, 16)
        case .Int32: return (false, 32)
        case .Int64: return (false, 64)
        case .Int: return (false, Swift.Int.bitWidth)
        default: return nil
        }
    }
    
    static internal func storedType(_ mftype: MfType) -> StoredType{
        switch mftype {
        case .Double:
            return .Double
        /*
        case .ComplexFloat:
            return .ComplexFloat
        case .ComplexDouble:
            return .ComplexDouble*/
        default: // all mftypes are stored as float except for double
            return .Float
        }
    }
    
    /// Returns whether the platform's `Int` is 32-bit.
    static public func is32bit() -> Bool{
        return MemoryLayout<Int>.size == MemoryLayout<Int32>.size
    }
    /// Returns whether the platform's `Int` is 64-bit.
    static public func is64bit() -> Bool{
        return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
    }
    //return MemoryLayout<Float>.stride
    
    //static internal func initializer<T: Numeric, U: Numeric>(_ mftype: MfType, value: T) -> U{
        
    //}
}

/// The type actually used to store the elements of an `MfArray` in memory.
public enum StoredType: Int{
    /// Stored as `Float`. Used by every `MfType` except `.Double`.
    case Float
    /// Stored as `Double`. Used by `MfType.Double`.
    case Double
    //case ComplexFloat
    //case ComplexDouble
    
    /// Returns the stored type with the higher precision.
    /// - Parameters:
    ///   - a: The first stored type.
    ///   - b: The second stored type.
    /// - Returns: `.Double` if either is `.Double`, otherwise `.Float`.
    static public func priority(_ a: StoredType, _ b: StoredType) -> StoredType{
        if a.rawValue < b.rawValue{
            return b
        }
        else{
            return a
        }
    }
    
    /// Returns the `MfType` corresponding to this stored type (`.Float` or `.Double`).
    public func to_mftype() -> MfType{
        switch self{
        case .Float:
            return .Float
        case .Double:
            return .Double
        /*
        case .ComplexFloat:
            return .ComplexFloat
        case .ComplexDouble:
            return .ComplexDouble*/
        }
    }
}

/// The color conversion code. Same as `cv2.COLOR_*`.
public enum MfColorConversion: Int{
    /// RGBA to grayscale (`cv2.COLOR_RGBA2GRAY`).
    case RGBA2GRAY
    /// RGBA to RGB, dropping alpha (`cv2.COLOR_RGBA2RGB`).
    case RGBA2RGB
    /// RGB to RGBA, adding an opaque alpha channel (`cv2.COLOR_RGB2RGBA`).
    case RGB2RGBA
    /// RGB to grayscale (`cv2.COLOR_RGB2GRAY`).
    case RGB2GRAY
    /// BGR to grayscale (`cv2.COLOR_BGR2GRAY`).
    case BGR2GRAY
    /// BGRA to grayscale (`cv2.COLOR_BGRA2GRAY`).
    case BGRA2GRAY
    /// Grayscale to RGB (`cv2.COLOR_GRAY2RGB`).
    case GRAY2RGB
    /// Grayscale to RGBA (`cv2.COLOR_GRAY2RGBA`).
    case GRAY2RGBA
    /// RGB to BGR (`cv2.COLOR_RGB2BGR`).
    case RGB2BGR
    /// BGR to RGB (`cv2.COLOR_BGR2RGB`).
    case BGR2RGB
    /// RGBA to BGRA (`cv2.COLOR_RGBA2BGRA`).
    case RGBA2BGRA
    /// BGRA to RGBA (`cv2.COLOR_BGRA2RGBA`).
    case BGRA2RGBA
    /// RGB to HSV (`cv2.COLOR_RGB2HSV`).
    case RGB2HSV
    /// HSV to RGB (`cv2.COLOR_HSV2RGB`).
    case HSV2RGB
}


/// The pixel extrapolation mode of vImage-based affine warping.
public enum MfAffineMode: Int{
    /// Fill pixels outside the source with the border color (`kvImageBackgroundColorFill`).
    case ColorFill
    /// Extend the edge pixels of the source (`kvImageEdgeExtend`).
    case EdgeExtend
}

/// The border type for filtering. Same as `cv2.BORDER_*`.
///
/// - Note: The default border type of OpenCV (`BORDER_REFLECT_101`) is not supported by vImage.
public enum MfBorderType: Int{
    /// Pad the constant value (0)
    case Constant
    /// Replicate the edge pixel
    case Replicate
}

/// The threshold type. Same as `cv2.THRESH_*`.
public enum MfThresholdType: Int{
    /// dst = src > thresh ? maxval : 0
    case Binary
    /// dst = src > thresh ? 0 : maxval
    case BinaryInv
    /// dst = src > thresh ? thresh : src
    case Trunc
    /// dst = src > thresh ? src : 0
    case ToZero
    /// dst = src > thresh ? 0 : src
    case ToZeroInv
}

/// The adaptive threshold method. Same as `cv2.ADAPTIVE_THRESH_*`.
public enum MfAdaptiveMethod: Int{
    /// The threshold is the mean of the neighborhood (`cv2.ADAPTIVE_THRESH_MEAN_C`).
    case Mean
    /// The threshold is the Gaussian-weighted sum of the neighborhood (`cv2.ADAPTIVE_THRESH_GAUSSIAN_C`).
    case Gaussian
}

/// The norm type for normalize. Same as `cv2.NORM_*`.
public enum MfNormType: Int{
    /// Infinity norm, i.e. the maximum absolute value (`cv2.NORM_INF`).
    case Inf
    /// L1 norm (`cv2.NORM_L1`).
    case L1
    /// L2 norm (`cv2.NORM_L2`).
    case L2
    /// Min-max scaling into a range (`cv2.NORM_MINMAX`).
    case MinMax
}

/// The shape of the structuring element. Same as `cv2.MORPH_RECT`, `cv2.MORPH_CROSS` and `cv2.MORPH_ELLIPSE`.
public enum MfMorphShape: Int{
    /// A rectangle.
    case Rect
    /// A cross.
    case Cross
    /// An ellipse.
    case Ellipse
}

/// The morphological operation. Same as `cv2.MORPH_*`.
public enum MfMorphOp: Int{
    /// Erosion.
    case Erode
    /// Dilation.
    case Dilate
    /// Opening (erosion followed by dilation).
    case Open
    /// Closing (dilation followed by erosion).
    case Close
    /// Morphological gradient (dilation minus erosion).
    case Gradient
    /// Top hat (source minus opening).
    case TopHat
    /// Black hat (closing minus source).
    case BlackHat
}

/// The rotation code. Same as `cv2.ROTATE_*`.
public enum MfRotateCode: Int{
    /// Rotate 90 degrees clockwise.
    case Rotate90Clockwise
    /// Rotate 180 degrees.
    case Rotate180
    /// Rotate 90 degrees counterclockwise.
    case Rotate90Counterclockwise
}

/// The interpolation method. Same as `cv2.INTER_*`.
public enum MfInterpolation: Int{
    /// Nearest-neighbor interpolation (`cv2.INTER_NEAREST`).
    case Nearest
    /// Bilinear interpolation (`cv2.INTER_LINEAR`).
    case Linear
    /// vImage's high quality resampling (Lanczos)
    case Lanczos
}

/// The padding mode. Same as `mode` of `numpy.pad`.
public enum MfPadMode: Int{
    /// Pads with a constant value
    case constant
    /// Pads with the edge values
    case edge
    /// Pads with the reflection of the vector mirrored on the first and last values
    case reflect
    /// Pads with the reflection of the vector mirrored along the edge
    case symmetric
    /// Pads with the wrap of the vector along the axis
    case wrap
}

/// The indexing of meshgrid. Same as `indexing` of `numpy.meshgrid`.
public enum MfMeshIndexing: Int{
    /// Cartesian indexing
    case xy
    /// Matrix indexing
    case ij
}

/// The resampling filter. Same as `PIL.Image.Resampling`.
public enum MfResample: Int{
    /// Nearest-neighbor resampling.
    case nearest
    /// Bilinear resampling.
    case bilinear
    /// Bicubic resampling.
    case bicubic
    /// Lanczos resampling.
    case lanczos
}

/// The window type. Same as `window` of `scipy.signal.get_window`.
public enum MfWindowType: Int{
    /// Hann window.
    case hann
    /// Hamming window.
    case hamming
    /// Blackman window.
    case blackman
    /// Bartlett (triangular) window.
    case bartlett
    /// Rectangular window (all ones).
    case boxcar
}

/// The normalization of mel filters. Same as `norm` of `librosa.filters.mel`.
public enum MfMelNorm: Int{
    /// Divide the triangular mel weights by the width of the mel band (area normalization)
    case slaney
}

/// The method to estimate the quantile. Same as `method` of `numpy.quantile`.
public enum MfQuantileMethod: Int{
    /// Linear interpolation between the two nearest values (default)
    case linear
    /// The lower one of the two nearest values
    case lower
    /// The higher one of the two nearest values
    case higher
    /// The nearest value (round half to even)
    case nearest
    /// The midpoint of the two nearest values
    case midpoint
}

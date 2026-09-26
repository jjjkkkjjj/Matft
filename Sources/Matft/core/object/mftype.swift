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

public enum MfType: Int{
    case None
    case Bool
    case UInt8
    case UInt16
    case UInt32
    case UInt64
    case UInt
    case Int8
    case Int16
    case Int32
    case Int64
    case Int
    case Float
    case Double
    case ComplexFloat
    case ComplexDouble
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
    
    static public func priority(_ a: MfType, _ b: MfType) -> MfType{
        if a.rawValue < b.rawValue{
            return b
        }
        else{
            return a
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
    
    static public func is32bit() -> Bool{
        return MemoryLayout<Int>.size == MemoryLayout<Int32>.size
    }
    static public func is64bit() -> Bool{
        return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
    }
    //return MemoryLayout<Float>.stride
    
    //static internal func initializer<T: Numeric, U: Numeric>(_ mftype: MfType, value: T) -> U{
        
    //}
}

public enum StoredType: Int{
    case Float
    case Double
    //case ComplexFloat
    //case ComplexDouble
    
    static public func priority(_ a: StoredType, _ b: StoredType) -> StoredType{
        if a.rawValue < b.rawValue{
            return b
        }
        else{
            return a
        }
    }
    
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

/// The color conversion code. Same as cv2.COLOR_*
public enum MfColorConversion: Int{
    case RGBA2GRAY
    case RGBA2RGB
    case RGB2RGBA
    case RGB2GRAY
    case BGR2GRAY
    case BGRA2GRAY
    case GRAY2RGB
    case GRAY2RGBA
    case RGB2BGR
    case BGR2RGB
    case RGBA2BGRA
    case BGRA2RGBA
    case RGB2HSV
    case HSV2RGB
}


public enum MfAffineMode: Int{
    case ColorFill
    case EdgeExtend
}

/// The border type for filtering. Same as cv2.BORDER_*
/// Note that the default border type of OpenCV (BORDER_REFLECT_101) is not supported by vImage.
public enum MfBorderType: Int{
    /// Pad the constant value (0)
    case Constant
    /// Replicate the edge pixel
    case Replicate
}

/// The threshold type. Same as cv2.THRESH_*
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

/// The adaptive threshold method. Same as cv2.ADAPTIVE_THRESH_*
public enum MfAdaptiveMethod: Int{
    case Mean
    case Gaussian
}

/// The norm type for normalize. Same as cv2.NORM_*
public enum MfNormType: Int{
    case Inf
    case L1
    case L2
    case MinMax
}

/// The shape of the structuring element. Same as cv2.MORPH_RECT, MORPH_CROSS and MORPH_ELLIPSE
public enum MfMorphShape: Int{
    case Rect
    case Cross
    case Ellipse
}

/// The morphological operation. Same as cv2.MORPH_*
public enum MfMorphOp: Int{
    case Erode
    case Dilate
    case Open
    case Close
    case Gradient
    case TopHat
    case BlackHat
}

/// The rotation code. Same as cv2.ROTATE_*
public enum MfRotateCode: Int{
    case Rotate90Clockwise
    case Rotate180
    case Rotate90Counterclockwise
}

/// The interpolation method. Same as cv2.INTER_*
public enum MfInterpolation: Int{
    case Nearest
    case Linear
    /// vImage's high quality resampling (Lanczos)
    case Lanczos
}

/// The padding mode. Same as `mode` of `np.pad`
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

/// The indexing of meshgrid. Same as `indexing` of `np.meshgrid`
public enum MfMeshIndexing: Int{
    /// Cartesian indexing
    case xy
    /// Matrix indexing
    case ij
}

//
//  math+method.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension MfArray{ // vForce
    
    /// Calculate the ceil for all elements
    /// - Returns: ceil mfarray
    public func ceil() -> MfArray<Int> where T.StoredType == Float{
        return Matft.math.ceil(self)
    }
    /// Calculate the ceil for all elements
    /// - Returns: ceil mfarray
    public func ceil() -> MfArray<Int64> where T.StoredType == Double{
        return Matft.math.ceil(self)
    }
    
    /// Calculate the floor for all elements
    /// - Returns: floor mfarray
    public func floor() -> MfArray<Int> where T.StoredType == Float{
        return Matft.math.floor(self)
    }
    /// Calculate the floor for all elements
    /// - Returns: floor mfarray
    public func floor() -> MfArray<Int64> where T.StoredType == Double{
        return Matft.math.floor(self)
    }
    
    /// Calculate the trunc for all elements
    /// - Returns: trunc mfarray
    public func trunc() -> MfArray<Int> where T.StoredType == Float{
        return Matft.math.trunc(self)
    }
    /// Calculate the trunc for all elements
    /// - Returns: trunc mfarray
    public func trunc() -> MfArray<Int64> where T.StoredType == Double{
        return Matft.math.trunc(self)
    }
    
    /// Calculate the nearest for all elements
    /// - Returns: nearest mfarray
    public func nearest() -> MfArray<Int> where T.StoredType == Float{
        return Matft.math.nearest(self)
    }
    /// Calculate the nearest for all elements
    /// - Returns: nearest mfarray
    public func nearest() -> MfArray<Int64> where T.StoredType == Double{
        return Matft.math.nearest(self)
    }
    
    /// Calculate the round for all elements
    /// - Parameters:
    ///   - decimals: (Optional) Int, default is 0, which is equivelent to nearest
    /// - Returns: round mfarray
    public func round(decimals: Int = 0) -> MfArray<Float> where T.StoredType == Float{
        return Matft.math.round(self, decimals: decimals)
    }
    /// Calculate the round for all elements
    /// - Parameters:
    ///   - decimals: (Optional) Int, default is 0, which is equivelent to nearest
    /// - Returns: round mfarray
    public func round(decimals: Int = 0) -> MfArray<Double> where T.StoredType == Double{
        return Matft.math.round(self, decimals: decimals)
    }
}


extension MfArray{ // vDSP
    
    
    /// Calculate sign of mfarray
    /// - Returns: The result mfarray
    public func sign() -> MfArray<MfArrayType>{
        return Matft.math.sign(self)
    }
}

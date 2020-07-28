//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/11.
//

import Foundation

extension MfArray where ArrayType: MfSignedNumeric{
    /**
       Calculate signed MfArray
       - parameters:
    */
    public func sign() -> MfArray<ArrayType>{
        Matft.math.sign(self)
    }
}

extension MfArray where ArrayType: StoredFloat{
    /**
       Return the ceiling of each element
       - parameters:
    */
    public func ceil() -> MfArray<Int32>{
        return Matft.math.ceil(self)
    }
    
    /**
       Return the floor of each element
       - parameters:
    */
    public func floor() -> MfArray<Int32>{
        return Matft.math.floor(self)
    }
    
    /**
       Return the interger truncation of each element
       - parameters:
    */
    public func trunc() -> MfArray<Int32>{
        return Matft.math.trunc(self)
    }
    
    /**
          Return the nearest interger of each element
          - parameters:
    */
    public func nearest() -> MfArray<Int32>{
        return Matft.math.nearest(self)
    }
    
    /**
          Return the round give by number of decimals of each element
          - parameters:
    */
    public func round(decimals: Int = 0) -> MfArray<Float>{
        return Matft.math.round(self, decimals: decimals)
    }
}

extension MfArray where ArrayType: StoredDouble{
    /**
       Return the ceiling of each element
       - parameters:
    */
    public func ceil() -> MfArray<Int64>{
        return Matft.math.ceil(self)
    }
    
    /**
       Return the floor of each element
       - parameters:
    */
    public func floor() -> MfArray<Int64>{
        return Matft.math.floor(self)
    }
    
    /**
       Return the interger truncation of each element
       - parameters:
    */
    public func trunc() -> MfArray<Int64>{
        return Matft.math.trunc(self)
    }
    
    /**
          Return the nearest interger of each element
          - parameters:
    */
    public func nearest() -> MfArray<Int64>{
        return Matft.math.nearest(self)
    }
    
    /**
          Return the round give by number of decimals of each element
          - parameters:
    */
    public func round(decimals: Int = 0) -> MfArray<Double>{
        return Matft.math.round(self, decimals: decimals)
    }
}


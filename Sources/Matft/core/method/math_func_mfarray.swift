//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/11.
//

import Foundation

extension MfArray{
    /**
       Return the ceiling of each element
       - parameters:
    */
    public func ceil() -> MfArray{
        return Matft.mfarray.math.ceil(self)
    }
    
    /**
       Return the floor of each element
       - parameters:
    */
    public func floor() -> MfArray{
        return Matft.mfarray.math.floor(self)
    }
    
    /**
       Return the interger truncation of each element
       - parameters:
    */
    public func trunc() -> MfArray{
        return Matft.mfarray.math.trunc(self)
    }
    
    /**
          Return the nearest interger of each element
          - parameters:
    */
    public func nearest() -> MfArray{
        return Matft.mfarray.math.nearest(self)
    }
    
    /**
          Return the round give by number of decimals of each element
          - parameters:
    */
    public func round(decimals: Int = 0) -> MfArray{
        return Matft.mfarray.math.round(self, decimals: decimals)
    }
    
    /**
       Calculate signed MfArray
       - parameters:
    */
    public func sign() -> MfArray{
        Matft.mfarray.math.sign(self)
    }
}

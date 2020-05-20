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
        return Matft.math.ceil(self)
    }
    
    /**
       Return the floor of each element
       - parameters:
    */
    public func floor() -> MfArray{
        return Matft.math.floor(self)
    }
    
    /**
       Return the interger truncation of each element
       - parameters:
    */
    public func trunc() -> MfArray{
        return Matft.math.trunc(self)
    }
    
    /**
          Return the nearest interger of each element
          - parameters:
    */
    public func nearest() -> MfArray{
        return Matft.math.nearest(self)
    }
    
    /**
          Return the round give by number of decimals of each element
          - parameters:
    */
    public func round(decimals: Int = 0) -> MfArray{
        return Matft.math.round(self, decimals: decimals)
    }
    
    /**
       Calculate signed MfArray
       - parameters:
    */
    public func sign() -> MfArray{
        Matft.math.sign(self)
    }
}

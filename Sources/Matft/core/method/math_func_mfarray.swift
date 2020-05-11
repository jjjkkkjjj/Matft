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
       Return the interfer truncation of each element
       - parameters:
    */
    public func trunc() -> MfArray{
        return Matft.mfarray.math.trunc(self)
    }
    
    /**
          Return the nearest interfer of each element
          - parameters:
    */
    public func nearest() -> MfArray{
        return Matft.mfarray.math.nearest(self)
    }
    
}

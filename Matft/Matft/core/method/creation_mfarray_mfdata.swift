//
//  creation_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension MfArray{
    /**
       Create deep copy of mfarray. Deep means copied mfarray will be different object from original one
       - parameters:
    */
    public func deepcopy() -> MfArray{
        return Matft.mfarray.deepcopy(self)
    }
    /**
       Create shallow copy of mfarray. Shallow means copied mfarray will be  sharing data with original one
       - parameters:
    */
    public func shallowcopy() -> MfArray{
        return Matft.mfarray.shallowcopy(self)
    }
    
    /**
        Flatten array
     */
    public func flatten(){
        var ret = Matft.mfarray.nums(0, shape: [self.size], mftype: self.mftype)
        
        //cblas_scopy(<#T##__N: Int32##Int32#>, <#T##__X: UnsafePointer<Float>!##UnsafePointer<Float>!#>, <#T##__incX: Int32##Int32#>, <#T##__Y: UnsafeMutablePointer<Float>!##UnsafeMutablePointer<Float>!#>, <#T##__incY: Int32##Int32#>)
    }
}
 
extension MfData{
    /**
       Create deep copy of mfdata. Deep means copied mfdata will be different object from original one
       - parameters:
    */
    public func deepcopy() -> MfData{
        return Matft.mfarray.mfdata.deepcopy(self)
    }
    /**
       Create shallow copy of mfdata. Shallow means copied mfdata will be  sharing data with original one
       - parameters:
    */
    public func shallowcopy() -> MfData{
        return Matft.mfarray.mfdata.shallowcopy(self)
    }
}

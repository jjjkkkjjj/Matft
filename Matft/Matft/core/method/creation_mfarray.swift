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
        Flatten 1d-mfarray
        - parameters:
             - mforder: (Optional) mforder, default is Row
     */
    public func flatten(_ mforder: MfOrder = .Row) -> MfArray{
        return Matft.mfarray.flatten(self, mforder: mforder)
    }
}
 /*
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
*/

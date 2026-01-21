//
//  creation_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    /**
       Create deep copy of mfarray. Deep means copied mfarray will be different object from original one
       - parameters:
            - order: (Optional) order, default is nil, which means close to either row or column major if possibe.
    */
    public func deepcopy(_ order: MfOrder? = nil) -> MfArray{
        return Matft.deepcopy(self, order: order)
    }
    /**
       Create shallow copy of mfarray. Shallow means copied mfarray will be  sharing data with original one
       - parameters:
    */
    public func shallowcopy() -> MfArray{
        return Matft.shallowcopy(self)
    }
    
    /**
        Flatten 1d-mfarray
        - parameters:
             - mforder: (Optional) mforder, default is Row
     */
    public func flatten(_ mforder: MfOrder = .Row) -> MfArray{
        return Matft.flatten(self, mforder: mforder)
    }
    
    /**
       Append values to the end of an array.
       - parameters:
            - values: appended mfarray
            - axis: the axis to append
    */
    public func append(values: MfArray, axis: Int? = nil) -> MfArray{
        return Matft.append(self, values: values, axis: axis)
    }
    /**
       Append values to the end of an array.
       - parameters:
            - value: appended value
            - axis: the axis to append
    */
    public func append<T: MfTypable>(value: T, axis: Int? = nil) -> MfArray{
        return Matft.append(self, values: MfArray([value]), axis: axis)
    }
    
    /**
       Take elements from an array along an axis.
       - parameters:
            - indices: indices mfarray
            - axis: the axis to append
    */
    public func take(indices: MfArray, axis: Int? = nil) -> MfArray{
        return Matft.take(self, indices: indices, axis: axis)
    }
    
    /**
       Insert values along the given axis before the given indices.
       - parameters:
            - indices: Index sequence
            - values: appended mfarray
            - axis: the axis to insert
    */
    public func insert(indices: [Int], values: MfArray, axis: Int? = nil) -> MfArray{
        return Matft.insert(self, indices: indices, values: values, axis: axis)
    }
    /**
       Insert values along the given axis before the given indices.
       - parameters:
            - indices: Index sequence
            - value: mftypable value
            - axis: the axis to insert
    */
    public func insert<T: MfTypable>(indices: [Int], value: T, axis: Int? = nil) -> MfArray{
        return Matft.insert(self, indices: indices, values: MfArray([value]), axis: axis)
    }
}
 /*
extension MfData{
    /**
       Create deep copy of mfdata. Deep means copied mfdata will be different object from original one
       - parameters:
    */
    public func deepcopy() -> MfData{
        return Matft.mfdata.deepcopy(self)
    }
    /**
       Create shallow copy of mfdata. Shallow means copied mfdata will be  sharing data with original one
       - parameters:
    */
    public func shallowcopy() -> MfData{
        return Matft.mfdata.shallowcopy(self)
    }
}
*/

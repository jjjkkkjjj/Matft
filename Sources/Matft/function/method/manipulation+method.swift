//
//  manipulation+method.swift
//  Matft
//

import Foundation

extension MfArray{
    /**
       Pad an array. Same as `np.pad`
       - parameters:
            - pad_width: The number of values padded to the edges of each axis. `[(before, after)]` for each axis, or one `(before, after)` for all axes
            - mode: (Optional) The padding mode, by default constant
            - constant_values: (Optional) The value to set the padded values for constant mode, by default 0
       - Returns: The padded mfarray
    */
    public func pad(pad_width: [(Int, Int)], mode: MfPadMode = .constant, constant_values: Double = 0) -> MfArray{
        return Matft.pad(self, pad_width: pad_width, mode: mode, constant_values: constant_values)
    }

    /**
       Pad an array with the same width for all edges. Same as `np.pad` with an int `pad_width`
       - parameters:
            - pad_width: The number of values padded to all edges
            - mode: (Optional) The padding mode, by default constant
            - constant_values: (Optional) The value to set the padded values for constant mode, by default 0
       - Returns: The padded mfarray
    */
    public func pad(pad_width: Int, mode: MfPadMode = .constant, constant_values: Double = 0) -> MfArray{
        return Matft.pad(self, pad_width: pad_width, mode: mode, constant_values: constant_values)
    }

    /**
       Calculate the n-th discrete difference along the given axis. Same as `np.diff`
       - parameters:
            - n: (Optional) The number of times values are differenced, by default 1
            - axis: (Optional) The axis along which the difference is taken, by default the last axis
    */
    public func diff(n: Int = 1, axis: Int = -1) -> MfArray{
        return Matft.diff(self, n: n, axis: axis)
    }
}

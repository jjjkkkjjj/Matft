//
//  setops+static.swift
//  Matft
//
//  unique and the set routines
//

import Foundation

extension Matft{
    /**
       Find the sorted unique elements of the flattened mfarray. Same as `np.unique`. NaNs are collapsed into one at the end
       - parameters:
            - mfarray: mfarray
       - Returns: The 1d unique values with the same type
    */
    public static func unique(_ mfarray: MfArray) -> MfArray{
        let values = _unique_sorted(_doubles(mfarray))
        return _mfarray(values, shape: [values.count], mftype: mfarray.mftype)
    }

    /**
       Find the sorted unique elements. Same as `np.unique_values`
       - parameters:
            - mfarray: mfarray
       - Returns: The 1d unique values with the same type
    */
    public static func unique_values(_ mfarray: MfArray) -> MfArray{
        return Matft.unique(mfarray)
    }

    /**
       Find the sorted unique elements and their counts. Same as `np.unique_counts`
       - parameters:
            - mfarray: mfarray
       - Returns: The unique values and the Int counts
    */
    public static func unique_counts(_ mfarray: MfArray) -> (values: MfArray, counts: MfArray){
        let ret = Matft.unique_all(mfarray)
        return (ret.values, ret.counts)
    }

    /**
       Find the sorted unique elements and the indices to reconstruct the input. Same as `np.unique_inverse`
       - parameters:
            - mfarray: mfarray
       - Returns: The unique values and the Int inverse indices with the same shape as the input
    */
    public static func unique_inverse(_ mfarray: MfArray) -> (values: MfArray, inverse_indices: MfArray){
        let ret = Matft.unique_all(mfarray)
        return (ret.values, ret.inverse_indices)
    }

    /**
       Find the sorted unique elements, the first indices, the inverse indices and the counts. Same as `np.unique_all`
       - parameters:
            - mfarray: mfarray
       - Returns:
            - values: The 1d unique values with the same type
            - indices: The Int indices of the first occurrences in the flattened input
            - inverse_indices: The Int indices to reconstruct the input from the unique values, with the same shape as the input
            - counts: The Int counts of the unique values
    */
    public static func unique_all(_ mfarray: MfArray) -> (values: MfArray, indices: MfArray, inverse_indices: MfArray, counts: MfArray){
        let values = _doubles(mfarray)
        // stable sort with NaN at the end
        let order = values.indices.sorted{
            let (a, b) = (values[$0], values[$1])
            if a.isNaN || b.isNaN{
                return !a.isNaN && b.isNaN || (a.isNaN == b.isNaN && $0 < $1)
            }
            return a < b || (a == b && $0 < $1)
        }

        var uniques: [Double] = [], firsts: [Double] = [], counts: [Double] = []
        var inverse = [Double](repeating: 0, count: values.count)
        for i in order{
            let v = values[i]
            // NaNs are equal to each other here (equal_nan=True)
            if let last = uniques.last, last == v || (last.isNaN && v.isNaN){
                counts[counts.count - 1] += 1
            }
            else{
                uniques.append(v)
                firsts.append(Double(i))
                counts.append(1)
            }
            inverse[i] = Double(uniques.count - 1)
        }

        let n = uniques.count
        return (_mfarray(uniques, shape: [n], mftype: mfarray.mftype),
                _mfarray(firsts, shape: [n], mftype: .Int),
                _mfarray(inverse, shape: mfarray.shape, mftype: .Int),
                _mfarray(counts, shape: [n], mftype: .Int))
    }

    /**
       Test whether each element is in test_elements. Same as `np.isin`
       - parameters:
            - element: mfarray
            - test_elements: The values against which to test each element
            - invert: (Optional) If true, the result is inverted, by default false
       - Returns: The Bool mfarray with the same shape as element
    */
    public static func isin(_ element: MfArray, _ test_elements: MfArray, invert: Bool = false) -> MfArray{
        // NaN is not equal to any value
        let tests = _unique_sorted(_doubles(test_elements).filter{ !$0.isNaN })
        let contains: (Double) -> Bool = tests.count <= 16 ? { tests.contains($0) } : {
            let i = _searchsorted(tests, $0, side: .left)
            return i < tests.count && tests[i] == $0
        }
        let values = _doubles(element).map{ contains($0) != invert ? 1.0 : 0.0 }
        return _mfarray(values, shape: element.shape, mftype: .Bool)
    }

    /**
       Find the sorted unique values that are in both of the mfarrays. Same as `np.intersect1d`
       - parameters:
            - ar1: mfarray
            - ar2: mfarray
       - Returns: The 1d sorted unique values
    */
    public static func intersect1d(_ ar1: MfArray, _ ar2: MfArray) -> MfArray{
        let b = Set(_doubles(ar2))
        return _set_result(_doubles(Matft.unique(ar1)).filter{ b.contains($0) }, ar1, ar2)
    }

    /**
       Find the sorted unique values that are in either of the mfarrays. Same as `np.union1d`
       - parameters:
            - ar1: mfarray
            - ar2: mfarray
       - Returns: The 1d sorted unique values
    */
    public static func union1d(_ ar1: MfArray, _ ar2: MfArray) -> MfArray{
        let values = _doubles(ar1) + _doubles(ar2)
        return Matft.unique(_mfarray(values, shape: [values.count], mftype: MfType.priority(ar1.mftype, ar2.mftype)))
    }

    /**
       Find the sorted unique values in ar1 that are not in ar2. Same as `np.setdiff1d`
       - parameters:
            - ar1: mfarray
            - ar2: mfarray
       - Returns: The 1d sorted unique values
    */
    public static func setdiff1d(_ ar1: MfArray, _ ar2: MfArray) -> MfArray{
        let b = Set(_doubles(ar2))
        let values = _doubles(Matft.unique(ar1)).filter{ !b.contains($0) }
        return _mfarray(values, shape: [values.count], mftype: ar1.mftype)
    }
}

/// Sorted unique values. NaNs are collapsed into one at the end
fileprivate func _unique_sorted(_ values: [Double]) -> [Double]{
    var sorted = values.filter{ !$0.isNaN }
    let hasNaN = sorted.count != values.count
    _radix_sort(&sorted)
    var ret: [Double] = []
    ret.reserveCapacity(sorted.count)
    for v in sorted where ret.last != v{
        ret.append(v)
    }
    if hasNaN{
        ret.append(Double.nan)
    }
    return ret
}

fileprivate func _set_result(_ values: [Double], _ ar1: MfArray, _ ar2: MfArray) -> MfArray{
    return _mfarray(values, shape: [values.count], mftype: MfType.priority(ar1.mftype, ar2.mftype))
}

/// LSD radix sort of the non-NaN Double values (4 passes of 16 bits). It is much faster than the comparison sort for large arrays
internal func _radix_sort(_ values: inout [Double]){
    let n = values.count
    if n < 1024{
        values.sort()
        return
    }
    // map the bits to the unsigned keys whose order is the same as the values
    var keys = values.map{
        v -> UInt64 in
        let bits = v.bitPattern
        return bits >> 63 == 1 ? ~bits : bits | (1 << 63)
    }
    var buffer = [UInt64](repeating: 0, count: n)
    var counts = [Int](repeating: 0, count: 1 << 16)
    keys.withUnsafeMutableBufferPointer{
        var src = $0
        buffer.withUnsafeMutableBufferPointer{
            var dst = $0
            for pass in 0..<4{
                let shift = UInt64(pass * 16)
                for i in 0..<counts.count{
                    counts[i] = 0
                }
                for k in src{
                    counts[Int((k >> shift) & 0xFFFF)] += 1
                }
                var offset = 0
                for i in 0..<counts.count{
                    let c = counts[i]
                    counts[i] = offset
                    offset += c
                }
                for k in src{
                    let digit = Int((k >> shift) & 0xFFFF)
                    dst[counts[digit]] = k
                    counts[digit] += 1
                }
                swap(&src, &dst)
            }
        }
    }
    // after the even number of passes, the result is in keys
    for i in 0..<n{
        let k = keys[i]
        values[i] = Double(bitPattern: k >> 63 == 1 ? k & ~(1 << 63) : ~k)
    }
}

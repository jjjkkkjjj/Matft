
import Foundation

extension MfArray: Collection{
    /// The position of the first sub-array along the first axis. Always 0.
    public var startIndex: Int { return 0 }
    /// The position one past the last sub-array along the first axis, i.e. `shape[0]` (0 for a 0-dimensional array).
    public var endIndex: Int { return self.ndim > 0 ? self.shape[0] : 0 }
    
    /// Returns the position immediately after the given index.
    /// - Parameters:
    ///   - i: A valid index.
    /// - Returns: `i + 1`.
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    /// Accesses the sub-array at the given position along the first axis, so that `MfArray` can be iterated with `for ... in`.
    ///
    /// Equivalent to `a[index]` in Numpy, except that the result is never a scalar:
    /// for a 1-dimensional array a shape `[1]` array is returned. Use `item(index:type:)` to get a scalar.
    /// Negative indices count from the end.
    /// - Parameters:
    ///   - index: The position along the first axis.
    /// - Returns: The sub-array with shape `shape[1...]` (or `[1]` for a 1-dimensional array).
    public subscript(index: Int) -> MfArray {
        var indices: [Any] = [index]
        let ret = self._get_mfarray(indices: &indices)
        return ret.ndim > 0 ? ret : ret.expand_dims(axis: 0)// avoid scalar, but I think this is not efficient way
    }
}

extension MfArray: BidirectionalCollection{
    /// Returns the position immediately before the given index.
    /// - Parameters:
    ///   - i: A valid index.
    /// - Returns: `i - 1`.
    public func index(before i: Int) -> Int {
        return i - 1
    }
}

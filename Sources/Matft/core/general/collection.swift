
import Foundation

extension MfArray: Collection{
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return self.ndim > 0 ? self.shape[0] : 0 }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public subscript(index: Int) -> MfArray {
        var indices: [Any] = [index]
        let ret = self._get_mfarray(indices: &indices)
        return ret.ndim > 0 ? ret : ret.expand_dims(axis: 0)// avoid scalar, but I think this is not efficient way
    }
}

extension MfArray: BidirectionalCollection{
    public func index(before i: Int) -> Int {
        return i - 1
    }
}

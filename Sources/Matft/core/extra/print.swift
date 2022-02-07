//
//  print.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import Foundation

extension MfArray: CustomStringConvertible{
    public var description: String{
        var desc = "mfarray = \n"
        if self.size == 0{
            desc += "\t[], type=\(MfArrayType.self), shape=\(self.shape)"
            return desc
        }
        
        desc += String(repeating: "[", count: self.ndim)
        
        let flattenData = self.data
        var shape = self.shape
        var strides = self.strides
        
        if self.size > 1000{//if size > 1000, some elements left out will be viewed
            
            // Create a generator for indexes left out
            let flattenLOIndSeq = FlattenLOIndSequence(storedSize: self.storedSize, shape: &shape, strides: &strides)
            
            var lastIndices: [Int]? = nil
            for (flattenIndex, indices) in flattenLOIndSeq{
                
                if var indices = indices, let flattenIndex = flattenIndex{
                    desc += "\t\(flattenData[flattenIndex + self.offsetIndex]),\t"
                    
                    if indices.last! == shape.last! - 1{
                        let clousureNum = _clousure_number(mfarray: self, indices: &indices)
                        //remove "\t" and ","
                        desc = String(desc.dropLast(2))
                        //append "]", "," "\n" and "["
                        desc += String(repeating: "]", count: clousureNum) + "," + String(repeating: "\n", count: clousureNum) + String(repeating: "[", count: clousureNum)
                    }
                    lastIndices = indices
                }
                else{ //skip
                    if var lastIndices = lastIndices, lastIndices.last! == shape.last! - 1{// \t and \n
                        
                        let clousureNum = _clousure_number(mfarray: self, indices: &lastIndices)

                        //remove \n and [
                        desc = String(desc.dropLast(2 * clousureNum))
                        // first half \n
                        desc += String(repeating: "\n", count: clousureNum)
                        // append skip center of \n
                        desc += "...,\t"
                        // second half \n
                        desc += String(repeating: "\n", count: clousureNum)
                        // recreate [
                        desc += String(repeating: "[", count: clousureNum)
                    }
                    else{ // \t only
                        desc += "\t...,\t"
                    }
                }
            }
        }
        else{ // all elements will be viewed
            let flattenIndSeq = FlattenIndSequence(shape: &shape, strides: &strides)
            
            for var ret in flattenIndSeq{
                desc += "\t\(flattenData[ret.flattenIndex + self.offsetIndex]),\t"

                if ret.indices.last! == shape.last! - 1{
                    let clousureNum = _clousure_number(mfarray: self, indices: &ret.indices)
                    //remove "\t" and ","
                    desc = String(desc.dropLast(2))
                    //append "]", "," "\n" and "["
                    desc += String(repeating: "]", count: clousureNum) + "," + String(repeating: "\n", count: clousureNum) + String(repeating: "[", count: clousureNum)
                }
            }
        }
        //remove redundunt "[", "\n" and "\n"
        desc = String(desc.dropLast((self.ndim - 1)*2 + 2))
        //append mfarray  info
        desc += " type=\(MfArrayType.self), shape=\(self.shape)"
        
        return desc
        
    }

}

extension MfData: CustomStringConvertible{
    public var description: String{
        var ret = ""
        
        ret += "Original Type\t: \(MfArrayType.self)\n"
        ret += "Stored Type\t\t: \(MfArrayStoredType.self)\n"
        ret += "Raw Data:\n"
        ret += "\(self.storedData)\n"
        
        ret += "\n"
        
        ret += "isView\t: \(self._isView)\n"
        ret += "offset\t: \(self.offset)\n"
        
        return ret
    }
}

extension MfStructure: CustomStringConvertible{
    public var description: String{
        var ret = ""
        ret += "shape\t: \(self.shape)\n"
        ret += "strides\t: \(self.strides)\n"
        
        ret += "\n"
        
        ret += "Row contiguous\t\t: \(self.row_contiguous)\n"
        ret += "Column contiguous\t: \(self.column_contiguous)\n"
        
        return ret
    }
}


/// Count clousure "[" number
/// - Parameters:
///   - mfarray: Input mfarray
///   - indices: Index array of mfarray
/// - Returns: The number of "["
fileprivate func _clousure_number<T>(mfarray: MfArray<T>, indices: inout [Int]) -> Int{
    var clousureNum = 1
    let shape = mfarray.shape
    for axis in (0..<indices.count - 1).reversed(){
        if indices[axis] == shape[axis] - 1{
            clousureNum += 1
        }
        else{
            break
        }
    }
    return clousureNum
}
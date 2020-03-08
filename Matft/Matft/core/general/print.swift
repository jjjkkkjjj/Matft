//
//  print_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray: CustomStringConvertible{
    public var description: String{
        var desc = "mfarray = \n"
        desc += String(repeating: "[", count: self.shapeptr.count)
        
        let flattenData = self.data
        
        if self.size > 1000{//if size > 1000, some elements left out will be viewed
            let flattenLOIndSeq = FlattenLOIndSequence(storedSize: self.storedSize, shapeptr: self.shapeptr, stridesptr: self.stridesptr)
            
            var lastIndices: [Int]? = nil
            for (flattenIndex, indices) in flattenLOIndSeq{
                
                if var indices = indices, let flattenIndex = flattenIndex{
                    desc += "\t\(flattenData[flattenIndex]),\t"
                    
                    if indices.last! == self.shapeptr.last! - 1{
                        let clousureNum = _clousure_number(mfarray: self, indices: &indices)
                        //remove "\t" and ","
                        desc = String(desc.dropLast(2))
                        //append "]", "," "\n" and "["
                        desc += String(repeating: "]", count: clousureNum) + "," + String(repeating: "\n", count: clousureNum) + String(repeating: "[", count: clousureNum)
                    }
                    lastIndices = indices
                }
                else{ //skip
                    if var lastIndices = lastIndices, lastIndices.last! == self.shapeptr.last! - 1{// \t and \n
                        
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
            let flattenIndSeq = FlattenIndSequence(shapeptr: self.shapeptr, stridesptr: self.stridesptr)
            for var ret in flattenIndSeq{
                desc += "\t\(flattenData[ret.flattenIndex]),\t"

                if ret.indices.last! == self.shapeptr.last! - 1{
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
        desc += " type=\(self.mftype), shape=\(self.shape)"
        
        return desc
    }
}

/*
//count clousure "[" number
fileprivate func _clousure_number(mfarray: MfArray, ind: Int) -> Int{
    var clousureNum = 1
    
    var counts = Array(mfarray.shapeptr)
    counts[counts.count - 1] = 1
    for axis in stride(from: counts.count - 2, through: 0, by: -1){
        counts[axis] = counts[axis + 1] * mfarray.shapeptr[axis + 1]
    }
    
    var quotient = ind

    for axis in 0..<counts.count{
        let count = counts[axis]
        let dim = mfarray.shapeptr[axis]
        clousureNum = (quotient / count == count - 1) && (quotient % count == dim - 1) ? clousureNum + 1 : clousureNum
        quotient = quotient % count
    }

    return clousureNum
}*/

//count clousure "[" number
fileprivate func _clousure_number(mfarray: MfArray, indices: inout [Int]) -> Int{
    var clousureNum = 1
    for axis in (0..<indices.count - 1).reversed(){
        if indices[axis] == mfarray.shapeptr[axis] - 1{
            clousureNum += 1
        }
        else{
            break
        }
    }
    return clousureNum
}



extension MfFlags: CustomStringConvertible{
    public var description: String{
        var ret = ""
        ret += "Row contiguous\t\t: \(self.row_contiguous)\n"
        ret += "Column contiguous\t: \(self.column_contiguous)\n"
        return ret
    }
}

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
        var shapeptr = self.shapeptr
        if self.size > 1000{//if size > 1000, some elements left out will be viewed
            var indices_ = get_leaveout_indices(&shapeptr)
            
            for (i, indices) in indices_.enumerated(){
                
                if var indices = indices{
                    desc += "\t\(self[indices]),\t"
                    
                    if indices.last! == self.shapeptr.last! - 1{
                        let clousureNum = _clousure_number(mfarray: self, indices: &indices)
                        //remove "\t" and ","
                        desc = String(desc.dropLast(2))
                        //append "]", "," "\n" and "["
                        desc += String(repeating: "]", count: clousureNum) + "," + String(repeating: "\n", count: clousureNum) + String(repeating: "[", count: clousureNum)
                    }
                }
                else{ //skip
                    if indices_[i - 1]?.last! == self.shapeptr.last! - 1{// \t and \n
                        
                        let clousureNum = _clousure_number(mfarray: self, indices: &indices_[i - 1]!)

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
            let indices_ = get_indices(&shapeptr)

            for indices in indices_{
                desc += "\t\(self[indices]),\t"
                
                if indices.last! == self.shapeptr.last! - 1{
                    var indices = indices
                    let clousureNum = _clousure_number(mfarray: self, indices: &indices)
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


//
//  Print.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/13.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension MfArray: MfType{
    //for print function
    public var description: String{
        var desc = "mfarray = \n"
        desc += String(repeating: "[", count: self.shape.count)
        
        if self.size > 1000{//if size > 1000, some elements left out will be viewed
            var indices_ = _get_leaveout_indices(self.shape)
            
            for (i, indices) in indices_.enumerated(){
                
                if var indices = indices{
                    desc += "\t\(self[indices]),\t"
                    
                    if indices.last! == self.shape.last! - 1{
                        let clousureNum = self.clousure_number(indices: &indices)
                        //remove "\t" and ","
                        desc = String(desc.dropLast(2))
                        //append "]", "," "\n" and "["
                        desc += String(repeating: "]", count: clousureNum) + "," + String(repeating: "\n", count: clousureNum) + String(repeating: "[", count: clousureNum)
                    }
                }
                else{ //skip
                    if indices_[i - 1]?.last! == self.shape.last! - 1{// \t and \n
                        
                        let clousureNum = self.clousure_number(indices: &indices_[i - 1]!)

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
            let indices_ = _get_indices(self.shape)
            
            for indices in indices_{
                desc += "\t\(self[indices]),\t"
                
                if indices.last! == self.shape.last! - 1{
                    var indices = indices
                    let clousureNum = self.clousure_number(indices: &indices)
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
        desc += " type=\(String(describing: T.self)), shape=\(self.shape)"
        
        return desc
    }
    
    //count clousure "[" number
    private func clousure_number(indices: inout [Int]) -> Int{
        var clousureNum = 1
        for axis in (0..<indices.count - 1).reversed(){
            if indices[axis] == self.shape[axis] - 1{
                clousureNum += 1
            }
            else{
                break
            }
        }
        return clousureNum
    }
}

extension MfArrayType: CustomStringConvertible{
    public var description: String {
        var desc = ""
        
        desc += "TYPE\t: \(self.type.rawValue)\n"
        desc += "ORDER\t: \(self.order.rawValue)\n"
        desc += "C_CONTIGUOUS\t: \(self.C_CONTIGUOUS)\n"
        desc += "F_CONTIGUOUS\t: \(self.F_CONTIGUOUS)\n"
        
        return desc
    }
}

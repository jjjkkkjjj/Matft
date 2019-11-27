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
    //if size > 1000, leave out
    public var description: String{
        var string = "mfarray = \n"
        string.append(String(repeating: "[", count: self.shape.count))
        
        var indices = Array<Int>(repeating: 0, count: self.shape.count)
        
        while indices[0] !=  self.shape[0]{
            string.append("\t\(self[indices]),\t")
            
            indices[indices.count - 1] += 1
            
            var repeatNumber = -1//store the number [ and \n
            for i in 0..<indices.count - 1{
                let index = indices.count - 1 - i//descent order for
                if indices[index] == self.shape[index]{
                    indices[index] = 0
                    indices[index - 1] += 1
                    
                    repeatNumber = i + 1
                }
            }
            
            if repeatNumber != -1{
                string = String(string.dropLast(2))
                string.append(String(repeating: "]", count: repeatNumber) + "," + String(repeating: "\n", count: repeatNumber) + String(repeating: "[", count: repeatNumber))
            }
        }
        
        string = String(string.dropLast((self.ndim - 1)*2 + 1))
        string.append("], type=\(String(describing: T.self)), shape=\(self.shape)")
        
        return string
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

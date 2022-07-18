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
        if self.size == 0{
            desc += "\t[], type=\(self.mftype), shape=\(self.shape)"
            return desc
        }
        
        desc += String(repeating: "[", count: self.ndim)
        
        let flattenData = self.data
        let flattenImagData = self.data_imag
        let isRaal = self.mfdata._isReal
        var shape = self.shape
        var strides = self.strides
        
        var formatter = NumberFormatter()
        formatter.positivePrefix = formatter.plusSign
        
        if self.size > 1000{//if size > 1000, some elements left out will be viewed
            let flattenLOIndSeq = FlattenLOIndSequence(storedSize: self.storedSize, shape: &shape, strides: &strides)
            
            var lastIndices: [Int]? = nil
            for (flattenIndex, indices) in flattenLOIndSeq{
                
                if var indices = indices, let flattenIndex = flattenIndex{
                    if isRaal{
                        desc += "\t\(flattenData[flattenIndex + self.offsetIndex]),\t"
                    }
                    else{
                        desc += "\t\(flattenData[flattenIndex + self.offsetIndex]) \(formatter.string(for: flattenImagData![flattenIndex + self.offsetIndex]) ?? "")j,\t"
                    }
                    
                    if indices.last! == shape.last! - 1{
                        let clousureNum = _clousure_number(shape: &shape, indices: &indices)
                        //remove "\t" and ","
                        desc = String(desc.dropLast(2))
                        //append "]", "," "\n" and "["
                        desc += String(repeating: "]", count: clousureNum) + "," + String(repeating: "\n", count: clousureNum) + String(repeating: "[", count: clousureNum)
                    }
                    lastIndices = indices
                }
                else{ //skip
                    if var lastIndices = lastIndices, lastIndices.last! == shape.last! - 1{// \t and \n
                        
                        let clousureNum = _clousure_number(shape: &shape, indices: &lastIndices)

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
                if isRaal{
                    desc += "\t\(flattenData[ret.flattenIndex + self.offsetIndex]),\t"
                }
                else{
                    desc += "\t\(flattenData[ret.flattenIndex + self.offsetIndex]) \(formatter.string(for: flattenImagData![ret.flattenIndex + self.offsetIndex]) ?? "")j,\t"
                }

                if ret.indices.last! == shape.last! - 1{
                    let clousureNum = _clousure_number(shape: &shape, indices: &ret.indices)
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
fileprivate func _clousure_number(shape: inout [Int], indices: inout [Int]) -> Int{
    var clousureNum = 1
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

extension MfData: CustomStringConvertible{
    public var description: String{
        var ret = ""
        
        ret += "Original Type\t: \(self.mftype)\n"
        ret += "Stored Type\t\t: \(self.storedType)\n"
        ret += "isReal\t: \(self._isReal)\n"
        
        switch self.storedType{
        case .Float:
            let ptrF = self.data_real.bindMemory(to: Float.self, capacity: self.storedSize)
            ret += "Raw Data:\n"
            ret += "\(Array(UnsafeMutableBufferPointer(start: ptrF, count: self.storedSize)))\n"
            
            if !self._isReal{
                let ptriF = self.data_imag!.bindMemory(to: Float.self, capacity: self.storedSize)
                ret += "Raw Imag Data:\n"
                ret += "\(Array(UnsafeMutableBufferPointer(start: ptriF, count: self.storedSize)))\n"
            }
            
        case .Double:
            let ptrD = self.data_real.bindMemory(to: Double.self, capacity: self.storedSize)
            ret += "Raw Data:\n"
            ret += "\(Array(UnsafeMutableBufferPointer(start: ptrD, count: self.storedSize)))\n"
            
            if !self._isReal{
                let ptriD = self.data_imag!.bindMemory(to: Double.self, capacity: self.storedSize)
                ret += "Raw Imag Data:\n"
                ret += "\(Array(UnsafeMutableBufferPointer(start: ptriD, count: self.storedSize)))\n"
            }
        }
        
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

extension MfComplexArray: CustomStringConvertible{
    public var description: String{
        var desc = "mfcomplexarray = \n"
        if self.size == 0{
            desc += "\t[], type=Complex\(self.mftype), shape=\(self.shape)"
            return desc
        }
        
        desc += String(repeating: "[", count: self.ndim)
        
        let data = self.data
        let real_flattenData = data.real
        let imag_flattenData = data.imag
        let imag = "j"
        var shape = self.shape
        var strides = self.strides
        
        if self.size > 1000{//if size > 1000, some elements left out will be viewed
            let flattenLOIndSeq = FlattenLOIndSequence(storedSize: self.storedSize, shape: &shape, strides: &strides)
            
            var lastIndices: [Int]? = nil
            for (flattenIndex, indices) in flattenLOIndSeq{
                
                if var indices = indices, let flattenIndex = flattenIndex{
                    desc += "\t\(real_flattenData[flattenIndex + self.offsetIndex]) \(imag_flattenData[flattenIndex + self.offsetIndex])\(imag),\t"
                    
                    if indices.last! == shape.last! - 1{
                        let clousureNum = _clousure_number(shape: &shape, indices: &indices)
                        //remove "\t" and ","
                        desc = String(desc.dropLast(2))
                        //append "]", "," "\n" and "["
                        desc += String(repeating: "]", count: clousureNum) + "," + String(repeating: "\n", count: clousureNum) + String(repeating: "[", count: clousureNum)
                    }
                    lastIndices = indices
                }
                else{ //skip
                    if var lastIndices = lastIndices, lastIndices.last! == shape.last! - 1{// \t and \n
                        
                        let clousureNum = _clousure_number(shape: &shape, indices: &lastIndices)

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
                desc += "\t\(real_flattenData[ret.flattenIndex + self.offsetIndex]) \(imag_flattenData[ret.flattenIndex + self.offsetIndex])\(imag),\t"

                if ret.indices.last! == shape.last! - 1{
                    let clousureNum = _clousure_number(shape: &shape, indices: &ret.indices)
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
        desc += " type=Complex\(self.mftype), shape=\(self.shape)"
        
        return desc
    }
}

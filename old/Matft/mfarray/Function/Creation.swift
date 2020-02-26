//
//  Creation.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/13.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension Matft.mfarray{
    //create mfarray repeating specified number (num)
    public static func nums<T: MfNumeric>(num: Double, type: T.Type, shape: [Int], order: String = "C") -> MfArray<T>{
        typealias TPointer = UnsafeMutableBufferPointer<Double>
        let dataPointer = TPointer.allocate(capacity: _shape2size(shape))
        let _ = dataPointer.initialize(repeating: num)

        return MfArray(data: dataPointer, type: type, shape: shape, order: order)
    }
    public static func nums_like<T: MfNumeric>(num: Double, type: T.Type, mfarray: MfArray<T>) -> MfArray<T>{
        let storedSize = _get_storedSize(mfarray: mfarray)
        
        typealias TPointer = UnsafeMutableBufferPointer<Double>
        let dataPointer = TPointer.allocate(capacity: storedSize)
        let _ = dataPointer.initialize(repeating: num)
        
        let info = MfArrayInfo(dataPointer: dataPointer, type: type, shape: mfarray.info.shape, strides: mfarray.info.strides, order: mfarray.info.flags.order)
        
        return MfArray(info: info)
    }
    
    //Return a 2-D array with ones on the diagonal and zeros elsewhere.
    public static func eye<T: MfNumeric>(_ n: Int, type: T.Type) -> MfArray<T>{
        typealias TPointer = UnsafeMutableBufferPointer<Double>
        let dataPointer = TPointer.allocate(capacity: n * n)
        let _ = dataPointer.initialize(repeating: 0)
        
        let ptr = dataPointer.baseAddress!
        for i in 0..<n{
            (ptr + i + i*n).pointee = 1
        }

        return MfArray(data: dataPointer, type: type, shape: [n, n], order: "C")
    }
    
    //copy
    //copy all data
    public static func deepcopy<T>(mfarray: MfArray<T>) -> MfArray<T>{
        /*
         print("pointer check")
         typealias IntPointer = UnsafeMutablePointer<Int>
         let dataPointer = IntPointer.allocate(capacity: 2)
         dataPointer.initialize(from: [1,2], count: 2)
         
         let newpointer = IntPointer.allocate(capacity: 2)
         memcpy(newpointer, dataPointer, MemoryLayout<Int>.size)
         print(dataPointer)
         print(newpointer)
         
         dataPointer.pointee = 3
         print(dataPointer.pointee)  //-> 3
         print(newpointer.pointee)   //-> /1
         print("finish pointer check")
         */
        /*
         let array = MfArray(mfarray: [[[1,2,3,4],[5,6,7,8]], [[9,10,11,12],[13,14,15,16]], [[17,18,19,20],[21,22,23,24]]], type: Int.self)
         let copiedArray = Matft.mfarray.deepcopy(mfarray: array)
         print(array[1,1,1]) //-> 14
         array[1,1,1] = 5
         print(array[1,1,1]) //-> 5
         print(copiedArray[1,1,1]) // ->14
         */
        let newInfo = mfarray.info.deepcopy()
        return MfArray(info: newInfo)
    }
    
    //flatten
    public static func flatten<T>(mfarray: MfArray<T>, shape: Int){
        
    }
}

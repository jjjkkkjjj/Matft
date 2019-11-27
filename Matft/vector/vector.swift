//
//  vector.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/01.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public class Vector<T>: MfType{
    //for print function
    public var description: String{
        var string = "Vector = "
        if !self.columned{
            string.append("[")
            for i in 0..<self.size{
                string.append(" \((self.data + i).pointee)")
            }
            string.append(" ], type=\(String(describing: T.self)), size=\(self.size)")
            
        }else{
            string.append("\n[")
            for i in 0..<self.size{
                string.append(" \((self.data + i).pointee)\n")
            }
            string = String(string.dropLast())
            string.append(" ], type=\(String(describing: T.self)), size=\(self.size)")
        }
        return string
    }
    
    var data: UnsafeMutablePointer<T>
    var size: Int
    /*
     columned == true means this is column vector
     columned == false means this is row vector
     */
    var columned: Bool
    
    init(vector: [T], columned: Bool = false){
        typealias TPointer = UnsafeMutablePointer<T>
        self.data = TPointer.allocate(capacity: vector.count)
        self.data.initialize(from: vector, count: vector.count)
        
        self.size = vector.count
        self.columned = columned
    }
    init(data: UnsafeMutablePointer<T>, size: Int, columned: Bool = false) {
        self.data = data
        self.size = size
        self.columned = columned
    }
    
    deinit {
        self.data.deallocate()
    }
    
    subscript(index: Int) -> T{
        precondition(_check_index(index: index, size: self.size), "Index is out of range")
        return (self.data + index).pointee
    }
    
    subscript(range: Range<Int>) -> Vector<T>{
        typealias TPointer = UnsafeMutablePointer<T>
        let newDataPointer = TPointer.allocate(capacity: range.count)
        newDataPointer.initialize(from: self.data + range[0], count: range.count)
        
        let new = Vector(data: newDataPointer, size: range.count, columned: self.columned)
        
        return new
    }
    /*
    subscript(indicesArray: [Any]) -> Vector<T>{
        
    }*/
}

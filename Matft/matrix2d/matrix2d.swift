//
//  3dmat.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/01.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

public class Matrix2d<T>: MfType{
    //for print function
    public var description: String{
        var string = "Matrix2d = \n["
        for row in 0..<self.shape[0]{
            string.append("[")
            for col in 0..<self.shape[1]{
                string.append(" \(self[row, col])")
            }
            string.append(" ]")
            if row != self.shape[0] - 1{
                string.append("\n")
            }
        }
        string.append("], type=\(String(describing: T.self)), shape=[\(self.shape[0]), \(self.shape[1])]")
        return string
    }
    
    var data: [T]
    var shape: [Int]
    var size: Int{
        var _size = 1
        for dim in shape{
            _size *= dim
        }
        return _size
    }
    /*
    var transpose: Matrix2d<T: MfNumeric>{
        let new = Matrix2d_nums(num: 0, type: T.self, shape: self.shape)
        for newrow_oldcol in 0..<self.shape[1]{
            for newcol_oldrow in 0..<self.shape[0]{
                new.data[newrow_oldcol*(self.shape[1] - 1) + newcol_oldrow] = self[newcol_oldrow, newrow_oldcol]
            }
        }
        return new
    }*/
    
    init(matrix: [[T]], shape: [Int]) {
        self.data = matrix.reduce([], +)
        precondition(shape.count == 2, "Matrix2d supports 2-dimentional matrix only")
        self.shape = shape
        precondition(self.data.count == self.size, "invalid elements number or shape")
    }
    
    
    
    init(data: [T], shape: [Int]) {
        self.data = data
        precondition(shape.count == 2, "Matrix2d supports 2-dimentional matrix only")
        self.shape = shape
        precondition(self.data.count == self.size, "invalid elements number or shape")
    }
    
    
    subscript(row: Int, col: Int) -> T{
        return self.data[row*(self.shape[0] - 1) + col]
    }
    /*
    subscript(range: Range){
        
    }*/
}


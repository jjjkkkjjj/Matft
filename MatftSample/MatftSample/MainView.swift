//
//  MainView.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/10/29.
//  Copyright © 2019 jkado. All rights reserved.
//

import UIKit
import Matft

class MainView: UIView {
    
    required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        
        //self.check_Vector()
        //self.check_Matrix2d()
        self.check_MfArray()
    }
    /*
     func check_Matrix2d(){
     let array = Matrix2d(matrix: [[1,2],[3,4],[5,6]], shape: [3, 2])
     let array2 = Matrix2d(matrix: [[1,2],[3,4],[5,6]], shape: [3, 2])
     //let array3 = Matrix2d(array: [[1,2],[3,4],[5,6]], type: Int.self)
     let a = array + array2
     print(a)
     }*/
    
    func check_MfArray(){
        /*
        let aaa = [[1,1,-1], [-2,0,1], [0,2,1]]
        let coefficients = MfArray(mfarray: aaa, type: Int.self).astype(Double.self)
        let y = MfArray(mfarray: [[2,1,3]], type: Int.self).astype(Double.self)
        print(coefficients)
        
        do{
            let inv = try Matft.mfarray.linalg.inverse(coefficients)
            let abc = Matft.mfarray.dot(left: inv, right: y.T)
            print(abc)
        }
        catch{
            print("no inverse matrix")
        }
        */

        let arr = MfArray(mfarray: [[0,1],[2,3]], type: Int.self)
        //print(arr + arr.T)
        let arrr = MfArray(mfarray: [0,1], type: Int.self)
        let arr2 = MfArray(mfarray: [[[ 0,  1,  2,  3],
                                      [ 4,  5,  6,  7]],
                                     
                                     [[ 8,  9, 10, 11],
                                      [12, 13, 14, 15]]], type: Int.self).T
        let arr22 = MfArray(mfarray: [[[ 0,  8],
                                       [ 4, 12]],
                                      
                                      [[ 1,  9],
                                       [ 5, 13]],
                                      
                                      [[ 2, 10],
                                       [ 6, 14]],
                                      
                                      [[ 3, 11],
                                       [ 7, 15]]], type: Int.self)

        let a = Matft.mfarray.nums(num: 2, type: Int.self, shape: [10, 10, 10, 10, 10])
        var start = Date()
        let c = a + a.T
        var elapsed = Date().timeIntervalSince(start)
        print(elapsed)
        print(c)
    }
    /*
     func check_Vector(){
     let array = Vector(vector: [1.0, 2.0, 3.0])
     let array2 = Vector(vector: [4.0, 5.0, 6.0], columned: true)
     //array[0..<2].printVec()
     
     let a = Matft.vector.inner(left: array, right: array2)
     print(a)
     }*/
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

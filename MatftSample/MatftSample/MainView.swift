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
        
        self.check_MfArray()
    }
    
    func check_MfArray(){
        
        let arr = try! MfArray([[0,1],[2,3]])
        print(arr.astype(.Double) * arr.T)
        /*
        let arrr = try! MfArray([0,1])
        let arrrr = try! MfArray([[0]])*/
        let arr2 = try! MfArray([[[ 0,  1,  2,  3],
                                  [ 4,  5,  6,  7]],
                                     
                                 [[ 8,  9, 10, 11],
                                  [12, 13, 14, 15]]])
        print(arr2)
        
        let arr22 = try! MfArray([[[ 0,  8],
                                   [ 4, 12]],
                                      
                                  [[ 1,  9],
                                   [ 5, 13]],
                                      
                                  [[ 2, 10],
                                   [ 6, 14]],
                                    
                                  [[ 3, 11],
                                   [ 7, 15]]])
        print(arr2.T + arr22)
        //print(arr.broadcast_to(shape: [4, 2, 2]))
        //print(arr + arr22)
        //print(arr22)
        
        /*
        let a = Matft.mfarray.nums(num: 2, type: Int.self, shape: [10, 10, 10, 10, 10, 10])
        var start = Date()
        let c = a + a.T
        var elapsed = Date().timeIntervalSince(start)
        print(elapsed)*/
        //print(c)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

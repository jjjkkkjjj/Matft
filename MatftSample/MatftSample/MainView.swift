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
        /*
        let a = Matft.mfarray.arange(start: 0, stop: 8, step: 1, shape: [2,2,2])
        print(a.transpose(axes: [1,2,0]))
        let b = a.transpose(axes: [1,2,0]).flatten(.Column)
        print(b)*/
        /*
        let arr = Matft.mfarray.arange(start: 0, stop: 100, step: 1, shape: [2, 5, 10], mftype: .Int)
        
        let a = arr[~~3, 1~<?~~2, 3~<]
        
        print(a + a)
        print(a)*/
        
        
        
        /*
        let arr2 = MfArray([[[ 0,  1,  2,  3],
                                  [ 4,  5,  6,  7]],
                                     
                                 [[ 8,  9, 10, 11],
                                  [12, 13, 14, 15]]])
        print(arr2.T)
        
        let arr22 = MfArray([[[ 0,  8],
                                   [ 4, 12]],
                                      
                                  [[ 1,  9],
                                   [ 5, 13]],
                                      
                                  [[ 2, 10],
                                   [ 6, 14]],
                                    
                                  [[ 3, 11],
                                   [ 7, 15]]])
        print(arr2.T + arr22)*/
        //print(arr.broadcast_to(shape: [4, 2, 2]))
        //print(arr + arr22)
        //print(arr22)
        /*
        let w = Matft.mfarray.arange(start: 0, stop: 81, step: 1, shape: [3,3,3,3]).transpose(axes: [0,2,1,3])
        print(w)
        print(w.reshape([1,9,1,3,3]))*/
        /*
        let a = Matft.mfarray.arange(start: 0, stop: 81, step: 1, shape: [3,3,3,3])
        let b = a.transpose(axes: [2,3,0,1])
        //print(a[0~, Matft.mfarray.newaxis()])
        //print(Matft.mfarray.squeeze(a[0~, Matft.mfarray.newaxis()]))
        print(Matft.mfarray.concatenate([a, b], axis: 1))*/
        
        /*
        let e = Matft.mfarray.arange(start: 0, stop: 27, step: 1, shape: [3,3,3])
        let eflip1 = e[0~, ~~-1, 0~]
        print(eflip1)
        let eflip1T = e.T
        print(eflip1T)
        print(eflip1 + eflip1T)
        print(e[-2~-1])*/
        
        /*
        let e = Matft.mfarray.arange(start: 0, stop: 27, step: 1, shape: [3,3,3])
        
        print(e[-2~1])
        print(e[-4~1])
        print(e[-1~1])
        print(e[0~4])
        print(e[-1~~-1])
        print(e[-2~0~-1])
        print(e[2~0~-1])
        print(e[-1~-8~-1])
        print(e[-8~0~-1])
        
        print(e[1,1,1])
        e[1,1] = 5
        print(e)
        
        //let c = Matft.mfarray.conv_order(e[-1~~-1], mforder: .Row)
        //print(c)
        //let d = Matft.mfarray.conv_order(e[-1~~-1], mforder: .Column)
        //print(d)
        print(e[-1~~-1])
        print(e.T)
        print(e[-1~~-1] + e.T)
        
        print(Matft.mfarray.stats.argmax(e))
        print(Matft.mfarray.stats.argmax(e, axis: 2))*/
        /*
        let a = MfArray([[4, 2],
                        [4, 5]])
        print(a)
        let b = Matft.mfarray.eye(dim: 2)
        print(b)
        //let b = MfArray([2,-7,9,1,1,1]).reshape([2,3])
        let x = try! Matft.mfarray.linalg.inv(a)
        print(x)*/
        let a = Matft.mfarray.arange(start: 0, stop: 2*2*4, step: 1, shape: [2,2,4])
        let b = Matft.mfarray.arange(start: 0, stop: 2*2*4, step: 1, shape: [2,4,2])
        print(a*&b)
        /*
        let a = Matft.mfarray.arange(start: 0, stop: 10*10*10*10*10*10, step: 1, shape: [10, 10, 10, 10, 10, 10], mftype: .Float)
        //let a = Matft.mfarray.arange(start: 0, stop: 3*3*3*3, step: 1, shape: [3, 3, 3, 3], mftype: .Float)
        //print(a.data)

        let b = a.transpose()
        let c = a.transpose(axes: [1,2,3,4,5,0])
        var start = Date()
        let d = b + c
        var elapsed = Date().timeIntervalSince(start)
        print(elapsed)*/
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

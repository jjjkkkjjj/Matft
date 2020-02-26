//
//  CreationMethod.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/13.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    //copyr
    public func view(mfarray: MfArray, shape: [Int]) -> MfArray{
        let newinfo = MfArrayInfo(base: mfarray, shape: mfarray.shape, strides: mfarray.strides, baseOffset: 0)
        return MfArray(info: newinfo)
    }
    
    //copy all data
    public func deepcopy() -> MfArray{
        let newInfo = self.info.deepcopy()
        return MfArray(info: newInfo)
    }
    
    //for broadcast
    public func broadcast_to(shape: [Int]) -> MfArray{
        let out_ndim = _shape2ndim(shape)
        var out_strides = Array<Int>(repeating: 0, count: out_ndim)
        
        let idim_start = out_ndim - self.ndim
        
        
        if idim_start < 0{
            fatalError("can't broadcast to fewer dimensions")
        }
        
        for idim in (idim_start..<out_ndim).reversed(){
            let strides_shape_value = self.shape[idim - idim_start]
            /* If it doesn't have dimension one, it must match */
            if strides_shape_value == 1{
                out_strides[idim] = 0
            }
            else if strides_shape_value != shape[idim]{
                fatalError("could not broadcast from shape \(self.strides.count), \(self.strides) into shape \(out_ndim), \(shape)")
            }
            else{
                out_strides[idim] = self.strides[idim - idim_start]
            }
        }
        
        /* New dimensions get a zero stride */
        for idim in 0..<idim_start{
            out_strides[idim] = 0
        }
        
        let newinfo = MfArrayInfo(base: self, shape: shape, strides: out_strides, baseOffset: 0)
        
        return MfArray(info: newinfo)
        /*
         let arr = MfArray(mfarray: [[1,2,3],[2,3,1]], type: Int.self)
         print(arr.broadcast_to(shape: [3,2,3]))
         //->mfarray =
         [[[    1,        2,        3],
         [    2,        3,        1]],
         
         [[    1,        2,        3],
         [    2,        3,        1]],
         
         [[    1,        2,        3],
         [    2,        3,        1]]], type=Int, shape=[3, 2, 3]
         */
    }
}

//
//  MatftTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/06.
//

import XCTest
@testable import Matft

final class MatftTests: XCTestCase {
    
    func testCreation(){
        let a = MfArray<Int>([[[ -8,  -7,  -6,  -5],
                              [ -4,  -3,  -2,  -1]],
                    
                             [[ 0,  1,  2,  3],
                              [ 4,  5,  6,  7]]])
        

        print(a.data)
        print(a.mfdata.storedPtr[0])
        print(a.shape)
        print(a.strides)
        print(a)
        print(a.mfdata)
        print(a.mfstructure)
    }
}

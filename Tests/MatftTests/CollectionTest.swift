//
//  CollectionTest.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import XCTest
//@testable import Matft
import Matft

final class CollectionTests: XCTestCase {
    
    func test_foreach() {
        do{

            let a = MfArray<Int>([[3, -19],
                             [-22, 4]] as [[Int]])
            
            let corr = [MfArray<Int>([3, -19] as [Int]), MfArray<Int>([-22, 4] as [Int])]
            for (i, aslice) in a.enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
            
            let corrT = [MfArray<Int>([3, -22] as [Int]), MfArray<Int>([-19, 4] as [Int])]
            for (i, aslice) in a.T.enumerated(){
                XCTAssertEqual(aslice, corrT[i])
            }
        }

        do{
            
            let a = MfArray<Int>([[2, 1, -3, 0],
                             [3, 1, 4, -5]] as [[Int]], mforder: .Column)


            let corr = [MfArray<Int>([2, 1, -3, 0] as [Int]), MfArray<Int>([3, 1, 4, -5] as [Int])]
            for (i, aslice) in a.enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
            
            let corrT = [MfArray<Int>([2, 3] as [Int]), MfArray<Int>([1, 1] as [Int]), MfArray<Int>([-3, 4] as [Int]), MfArray<Int>([0, -5] as [Int])]
            for (i, aslice) in a.T.enumerated(){
                XCTAssertEqual(aslice, corrT[i])
            }
        }
        
        do{
            let a = Matft.arange(start: 0, to: 3*3*3, by: 1, shape: [3, 3, 3])
            
            let corr = [MfArray<Int>([[0, 3, 6],
                                [1, 4, 7],
                                [2, 5, 8]] as [[Int]]),
                        MfArray<Int>([[ 9, 12, 15],
                                [10, 13, 16],
                                [11, 14, 17]] as [[Int]]),
                        MfArray<Int>([[18, 21, 24],
                                [19, 22, 25],
                                [20, 23, 26]] as [[Int]])]
            for (i, aslice) in a.transpose(axes: [0,2,1]).enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
        }
    }
    
    func test_toFlattenArray(){
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]] as [[Int]])
            
            let aflat = a.toFlattenArray()
            XCTAssertEqual(aflat, [3, -19, -22, 4])
            
            let aTflat = a.T.toFlattenArray()
            XCTAssertEqual(aTflat, [3, -22, -19, 4])
            
            let aTConvflat = a.T.toFlattenArray().map{ Float($0) }
            XCTAssertEqual(aTConvflat, [Float(3), -22, -19, 4])
        }
    }
}

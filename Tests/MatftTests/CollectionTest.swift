import XCTest
//@testable import Matft
import Matft

final class CollectionTests: XCTestCase {
    
    func test_foreach() {
        do{

            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            let corr = [MfArray<Int>([3, -19]), MfArray<Int>([-22, 4])]
            for (i, aslice) in a.enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
            
            let corrT = [MfArray<Int>([3, -22]), MfArray<Int>([-19, 4])]
            for (i, aslice) in a.T.enumerated(){
                XCTAssertEqual(aslice, corrT[i])
            }
        }

        do{
            
            let a = MfArray<Int>([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mforder: .Column)


            let corr = [MfArray<Int>([2, 1, -3, 0]), MfArray<Int>([3, 1, 4, -5])]
            for (i, aslice) in a.enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
            
            let corrT = [MfArray<Int>([2, 3]), MfArray<Int>([1, 1]), MfArray<Int>([-3, 4]), MfArray<Int>([0, -5])]
            for (i, aslice) in a.T.enumerated(){
                XCTAssertEqual(aslice, corrT[i])
            }
        }
        
        do{
            let a = Matft.arange(start: 0, to: 3*3*3, by: 1, shape: [3, 3, 3])
            
            let corr = [MfArray<Int>([[0, 3, 6],
                                [1, 4, 7],
                                [2, 5, 8]]),
                        MfArray<Int>([[ 9, 12, 15],
                                [10, 13, 16],
                                [11, 14, 17]]),
                        MfArray<Int>([[18, 21, 24],
                                [19, 22, 25],
                                [20, 23, 26]])]
            for (i, aslice) in a.transpose(axes: [0,2,1]).enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
        }
    }
    
    func test_scalarFlatMap(){
        do{
            let a = MfArray<Int>([[3, -19],
                             [-22, 4]])
            
            let aflat = a.scalarFlatMap{ $0 }
            XCTAssertEqual(aflat, [3, -19, -22, 4])
            
            let aTflat = a.T.scalarFlatMap{ $0 }
            XCTAssertEqual(aTflat, [3, -22, -19, 4])
            
            let aTConvflat = a.T.scalarFlatMap{ Float($0) }
            XCTAssertEqual(aTConvflat, [Float(3), -22, -19, 4])
        }
    }
}

import XCTest
//@testable import Matft
import Matft

final class CollectionTests: XCTestCase {
    
    func test_foreach() {
        do{

            let a = MfArray([[3, -19],
                             [-22, 4]])
            
            let corr = [MfArray([3, -19]), MfArray([-22, 4])]
            for (i, aslice) in a.enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
            
            let corrT = [MfArray([3, -22]), MfArray([-19, 4])]
            for (i, aslice) in a.T.enumerated(){
                XCTAssertEqual(aslice, corrT[i])
            }
        }

        do{
            
            let a = MfArray([[2, 1, -3, 0],
                             [3, 1, 4, -5]], mforder: .Column)


            let corr = [MfArray([2, 1, -3, 0]), MfArray([3, 1, 4, -5])]
            for (i, aslice) in a.enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
            
            let corrT = [MfArray([2, 3]), MfArray([1, 1]), MfArray([-3, 4]), MfArray([0, -5])]
            for (i, aslice) in a.T.enumerated(){
                XCTAssertEqual(aslice, corrT[i])
            }
        }
        
        do{
            let a = Matft.arange(start: 0, to: 3*3*3, by: 1, shape: [3, 3, 3])
            
            let corr = [MfArray([[0, 3, 6],
                                [1, 4, 7],
                                [2, 5, 8]]),
                        MfArray([[ 9, 12, 15],
                                [10, 13, 16],
                                [11, 14, 17]]),
                        MfArray([[18, 21, 24],
                                [19, 22, 25],
                                [20, 23, 26]])]
            for (i, aslice) in a.transpose(axes: [0,2,1]).enumerated(){
                XCTAssertEqual(aslice, corr[i])
            }
        }
    }
}

import XCTest
//@testable import Matft
import Matft

final class ProductTests: XCTestCase {
    
    
    func testCross() {
        do{

            let a = MfArray<Int>([1,2])
            let b = MfArray<Int>([2,2])
            
            XCTAssertEqual(a *^ b, MfArray<Int>([-2]))
        }

        do{
            
            let a = MfArray<Int>([[1,2],[2,2]])
            let b = MfArray<Int>([[2,2],[2,2]])
            
            XCTAssertEqual(a *^ b, MfArray<Int>([-2,  0]))

        }
        
        do{
            let a = MfArray<Int>([[1,2,3], [4,5,6], [7, 8, 9]])
            let b = MfArray<Int>([[7, 8, 9], [4,5,6], [1,2,3]])
            
            XCTAssertEqual(a *^ b, MfArray<Int>([[ -6,  12,  -6],
                                            [  0,   0,   0],
                                            [  6, -12,   6]]))
        }
        
        do{
            let a = MfArray<Int>([[1,2,3], [4,5,6]])
            let b = MfArray<Int>([[4,5,6], [1,2,3]])
            
            XCTAssertEqual(a *^ b, MfArray<Int>([[-3,  6, -3],
                                            [ 3, -6,  3]]))
        }
    }
    
    func testInner(){
        do{

            let a = MfArray<Int>([1,2,3])
            let b = MfArray<Int>([0,1,0])
            
            XCTAssertEqual(a *+ b, MfArray<Int>([2]))
        }
        
        do{

            let a = Matft.arange(start: 0, to: 24, by: 1).reshape([2, 3, 4])
            let b = Matft.arange(start: 0, to: 4, by: 1)
            
            XCTAssertEqual(a *+ b, MfArray<Int>([[ 14,  38,  62],
                                            [ 86, 110, 134]]))
        }
        
        do{

            let a = Matft.arange(start: 0, to: 18, by: 1).reshape([3, 2, 3])
            let b = Matft.arange(start: 0, to: 9, by: 1).reshape([3, 3])
            
            XCTAssertEqual(a *+ b, MfArray<Int>([[[  5,  14,  23],
                                             [ 14,  50,  86]],

                                            [[ 23,  86, 149],
                                             [ 32, 122, 212]],

                                            [[ 41, 158, 275],
                                             [ 50, 194, 338]]]))
        }
    }
    
}


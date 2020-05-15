import XCTest
//@testable import Matft
import Matft

final class ProductTests: XCTestCase {
    
    
    func testCross() {
        do{

            let a = MfArray([1,2])
            let b = MfArray([2,2])
            
            XCTAssertEqual(a *^ b, MfArray([-2]))
        }

        do{
            
            let a = MfArray([[1,2],[2,2]])
            let b = MfArray([[2,2],[2,2]])
            
            XCTAssertEqual(a *^ b, MfArray([-2,  0]))

        }
        
        do{
            let a = MfArray([[1,2,3], [4,5,6], [7, 8, 9]])
            let b = MfArray([[7, 8, 9], [4,5,6], [1,2,3]])
            
            XCTAssertEqual(a *^ b, MfArray([[ -6,  12,  -6],
                                            [  0,   0,   0],
                                            [  6, -12,   6]]))
        }
        
        do{
            let a = MfArray([[1,2,3], [4,5,6]])
            let b = MfArray([[4,5,6], [1,2,3]])
            
            XCTAssertEqual(a *^ b, MfArray([[-3,  6, -3],
                                            [ 3, -6,  3]]))
        }
    }
    

    
}

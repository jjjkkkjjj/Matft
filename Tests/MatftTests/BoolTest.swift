import XCTest
//@testable import Matft
import Matft

final class BoolTests: XCTestCase {
    
    func testAllEqual() {
        do{
            let a = MfArray([true, false])
            XCTAssertTrue(a == MfArray([true, false]))
        }
        
        do{
            let a = MfArray([2, 1, -3, 0])
            let b = MfArray([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertFalse(a == b)
            
            let c = MfArray([2.0, 1.0, -3.0, 0.0])
            XCTAssertTrue(a == c)
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray([[[0,1],
                             [2,3]],
            
                             [[4,5],
                              [6,7]]])
            XCTAssertTrue(a == b)
            XCTAssertFalse(a[0~,0~,~~-1] == Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]))
            
        }
    }
    
    //element-wise
    func testEqual(){
        do{
            let a = MfArray([true, false])
            XCTAssertEqual(a === MfArray([true, false]), MfArray([true, true]))
        }
        
        do{
            let a = MfArray([2, 1, -3, 0])
            let b = MfArray([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray([true, false, true, true]))
            XCTAssertEqual(-3 === b, MfArray([false, false, true, false]))
            
            let c = MfArray([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(a === c, MfArray([true, true, true, true]))
            XCTAssertEqual(a === 1, MfArray([false, true, false, false]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray([[[0,1],
                             [2,3]],
            
                             [[4,5],
                              [6,7]]])
            XCTAssertEqual(a === b, MfArray([[[true,true],
                                              [true,true]],
            
                                             [[true,true],
                                              [true,true]]]))
            
            XCTAssertEqual(a[0~,0~,~~-1] === Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]),
                                    MfArray([[[false,false],
                                              [false,false]],
            
                                             [[false,false],
                                              [false,false]]]))
        }
    }
    
    
    func testLogicalNot(){
        do{
            let a = MfArray([true, false])
            XCTAssertEqual(!a, MfArray([false, true]))
        }
        
        do{
            let a = MfArray([2, 1, -3, 0])
            let b = MfArray([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray([true, false, true, true]))
            XCTAssertEqual(!(a === b), MfArray([false, true, false, false]))
            
            let c = MfArray([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(!(a === c), MfArray([false, false, false, false]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray([[[0,1],
                             [2,3]],
            
                             [[4,5],
                              [6,7]]])
            XCTAssertEqual(!(a === b), MfArray([[[false,false],
                                              [false,false]],
            
                                             [[false,false],
                                              [false,false]]]))
            
            XCTAssertEqual(!(a[0~,0~,~~-1] === Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2])),
                                    MfArray([[[true,true],
                                              [true,true]],
                                    
                                             [[true,true],
                                              [true,true]]]))
        }
    }
    
    func testNotEqual(){
        do{
            let a = MfArray([true, false])
            XCTAssertEqual(a !== a, MfArray([false, false]))
        }
        
        do{
            let a = MfArray([2, 1, -3, 0])
            let b = MfArray([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray([true, false, true, true]))
            XCTAssertEqual(a !== b, MfArray([false, true, false, false]))
            XCTAssertEqual(2 !== b, MfArray([false, true, true, true]))
            
            let c = MfArray([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(a !== c, MfArray([false, false, false, false]))
            XCTAssertEqual(a !== 1, MfArray([true, false, true, true]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray([[[0,1],
                             [2,3]],
            
                             [[4,5],
                              [6,7]]])
            XCTAssertEqual(a !== b, MfArray([[[false,false],
                                              [false,false]],
            
                                             [[false,false],
                                              [false,false]]]))
            
            XCTAssertEqual(a[0~,0~,~~-1] !== Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]),
                                    MfArray([[[true,true],
                                              [true,true]],
                                    
                                             [[true,true],
                                              [true,true]]]))
        }
    }
}

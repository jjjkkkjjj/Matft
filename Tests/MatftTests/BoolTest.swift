import XCTest
//@testable import Matft
import Matft

final class BoolTests: XCTestCase {
    
    func testAllEqual() {
        do{
            let a = MfArray<Bool>([true, false])
            XCTAssertTrue(a == MfArray<Bool>([true, false]))
        }
        
        do{
            let a = MfArray<Double>([2, 1, -3, 0])
            let b = MfArray<Double>([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertFalse(a == b)
            
            let c = MfArray<Double>([2.0, 1.0, -3.0, 0.0])
            XCTAssertTrue(a == c)
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray<Int>([[[0,1],
                                   [2,3]],
            
                                  [[4,5],
                                   [6,7]]])
            XCTAssertTrue(a == b)
            XCTAssertFalse(a[0~<,0~<,~<~<-1] == Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]))
            
        }
    }
    
    //element-wise
    func testEqual(){
        do{
            let a = MfArray<Bool>([true, false])
            XCTAssertEqual(a === MfArray<Bool>([true, false]), MfArray<Bool>([true, true]))
        }
        
        do{
            let a = MfArray<Double>([2, 1, -3, 0])
            let b = MfArray<Double>([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray<Bool>([true, false, true, true]))
            XCTAssertEqual(-3 === b, MfArray<Bool>([false, false, true, false]))
            
            let c = MfArray<Double>([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(a === c, MfArray<Bool>([true, true, true, true]))
            XCTAssertEqual(a === 1, MfArray<Bool>([false, true, false, false]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray<Int>([[[0,1],
                                   [2,3]],
            
                                  [[4,5],
                                   [6,7]]])
            XCTAssertEqual(a === b, MfArray<Bool>([[[true,true],
                                                    [true,true]],
            
                                                   [[true,true],
                                                    [true,true]]]))
            
            XCTAssertEqual(a[0~<,0~<,~<~<-1] === Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]),
                                    MfArray<Bool>([[[false,false],
                                                    [false,false]],
            
                                                   [[false,false],
                                                    [false,false]]]))
        }
    }
    
    
    func testLogicalNot(){
        do{
            let a = MfArray<Bool>([true, false])
            XCTAssertEqual(!a, MfArray<Bool>([false, true]))
        }
        
        do{
            let a = MfArray<Double>([2, 1, -3, 0])
            let b = MfArray<Double>([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray<Bool>([true, false, true, true]))
            XCTAssertEqual(!(a === b), MfArray<Bool>([false, true, false, false]))
            
            let c = MfArray<Double>([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(!(a === c), MfArray<Bool>([false, false, false, false]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray<Int>([[[0,1],
                                   [2,3]],
            
                                    [[4,5],
                              [6,7]]])
            XCTAssertEqual(!(a === b), MfArray<Bool>([[[false,false],
                                                       [false,false]],
            
                                                      [[false,false],
                                                       [false,false]]]))
            
            XCTAssertEqual(!(a[0~<,0~<,~<~<-1] === Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2])),
                                    MfArray<Bool>([[[true,true],
                                                    [true,true]],
                                    
                                                   [[true,true],
                                                    [true,true]]]))
        }
    }
    
    func testNotEqual(){
        do{
            let a = MfArray<Bool>([true, false])
            XCTAssertEqual(a !== a, MfArray<Bool>([false, false]))
        }
        
        do{
            let a = MfArray<Double>([2, 1, -3, 0])
            let b = MfArray<Double>([2.0, 1.01, -3.0, 0.0])
            
            XCTAssertEqual(a === b, MfArray<Bool>([true, false, true, true]))
            XCTAssertEqual(a !== b, MfArray<Bool>([false, true, false, false]))
            XCTAssertEqual(2.0 !== b, MfArray<Bool>([false, true, true, true]))
            
            let c = MfArray<Double>([2.0, 1.0, -3.0, 0.0])
            XCTAssertEqual(a !== c, MfArray<Bool>([false, false, false, false]))
            XCTAssertEqual(a !== 1.0, MfArray<Bool>([true, false, true, true]))
        }
        
        do{
            let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
            let b = MfArray<Int>([[[0,1],
                                   [2,3]],
            
                                  [[4,5],
                                   [6,7]]])
            XCTAssertEqual(a !== b, MfArray<Bool>([[[false,false],
                                                    [false,false]],
            
                                                   [[false,false],
                                                    [false,false]]]))
            
            XCTAssertEqual(a[0~<,0~<,~<~<-1] !== Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]),
                                    MfArray<Bool>([[[true,true],
                                                    [true,true]],
                                    
                                                   [[true,true],
                                                    [true,true]]]))
        }
    }
}

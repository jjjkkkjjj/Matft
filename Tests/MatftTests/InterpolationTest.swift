import XCTest
//@testable import Matft
import Matft

final class InterpolationTests: XCTestCase {
    
    
    func testCubicSpline() {
        
        do{
            let x = Matft.arange(start: 1, to: 5.5, by: 0.5)
            let y = MfArray([1.0,2.25,4.0,6.25,9.0,12.25,16.0,20.25,25.0])
            let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y)
            XCTAssertEqual(cubicSpline.interpolate(x), y)
            XCTAssertEqual(cubicSpline.interpolate(MfArray([2.103])).scalar(Float.self)!, Float(4.424034))
        }
        
        do{
            let x = MfArray([-1, 2, 4, 5, 7])
            let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
            let new_x = Matft.arange(start: 0, to: 7, by: 1)
            let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y)
            XCTAssertEqual(cubicSpline.interpolate(x),  MfArray([0.2, -2.0, 9.1, 10.2, 6.4], mftype: .Float))
            XCTAssertEqual(cubicSpline.interpolate(new_x), MfArray([-7.06284153, -6.79213115, -2.0       ,  4.30142077,  9.1       ,
                                                                    10.2       ,  8.67125683], mftype: .Float))
        }
        
        
    }
    

}

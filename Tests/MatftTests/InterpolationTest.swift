// Temporally disabled until we are able to backport this functionality to WASM
#if !os(WASI)
import XCTest

@testable import Matft

final class InterpolationTests: XCTestCase {
    
    
    func testCubicSpline() {
        
        do{
            let x = Matft.arange(start: 1, to: 5.5, by: 0.5)
            let y = MfArray([1.0,2.25,4.0,6.25,9.0,12.25,16.0,20.25,25.0])
            let new_x = MfArray([1.2,3.3,4.2,4.8])
            let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y, bc_type: .natural)
            XCTAssertEqual(cubicSpline.interpolate(x), y)
            XCTAssertEqual(cubicSpline.interpolate(new_x), MfArray([ 1.46449485, 10.88962887, 17.63480412, 23.06449485], mftype: .Float))
        }
        
        do{
            let x = MfArray([-1, 2, 4, 5, 7])
            let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
            let new_x = Matft.arange(start: 0, to: 7, by: 1)
            let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y, bc_type: .natural)
            XCTAssertEqual(cubicSpline.interpolate(x),  MfArray([0.2, -2.0, 9.1, 10.2, 6.4], mftype: .Float))
            XCTAssertEqual(cubicSpline.interpolate(new_x), MfArray([-2.71997273, -3.99996592, -2.0        ,  3.75743865,  9.1       ,
            10.2       ,  8.81042945], mftype: .Float))
        }
        
        
    }

}
#endif

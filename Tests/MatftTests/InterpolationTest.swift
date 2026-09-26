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

    func testCubicSplineUnsortedInput() {
        let x = MfArray([-1, 2, 4, 5, 7])
        let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
        let new_x = MfArray([6, 0, 3, 1])
        let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y, bc_type: .natural)
        XCTAssertEqual(cubicSpline.interpolate(new_x), MfArray([8.81042945, -2.71997273, 3.75743865, -3.99996592], mftype: .Float))
    }

    func testCubicSplineClamped() {
        let x = MfArray([-1, 2, 4, 5, 7])
        let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
        let new_x = Matft.arange(start: 0, to: 7, by: 1)
        let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y, bc_type: .clamped)
        XCTAssertEqual(cubicSpline.interpolate(x), MfArray([0.2, -2.0, 9.1, 10.2, 6.4], mftype: .Float))
        XCTAssertEqual(cubicSpline.interpolate(new_x), MfArray([-1.13895021, -2.96678931, -2.0, 3.50099338, 9.1, 10.2, 8.03294702], mftype: .Float))
    }

    func testCubicSplineNotAKnot() {
        do{
            let x = MfArray([-1, 2, 4, 5, 7])
            let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
            let new_x = Matft.arange(start: 0, to: 7, by: 1)
            let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y, bc_type: .notAKnot)
            XCTAssertEqual(cubicSpline.interpolate(x), MfArray([0.2, -2.0, 9.1, 10.2, 6.4], mftype: .Float))
            XCTAssertEqual(cubicSpline.interpolate(new_x), MfArray([-7.06284153, -6.79213115, -2.0, 4.30142077, 9.1, 10.2, 8.67125683], mftype: .Float))
        }

        do{
            // 3 points: a parabola through all points
            let x = MfArray([0, 1, 3])
            let y = MfArray([1, 3, 2])
            let new_x = MfArray([0.5, 2.0, 2.5])
            let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y, bc_type: .notAKnot)
            XCTAssertEqual(cubicSpline.interpolate(x), MfArray([1.0, 3.0, 2.0], mftype: .Float))
            XCTAssertEqual(cubicSpline.interpolate(new_x), MfArray([2.20833333, 3.33333333, 2.875], mftype: .Float))
        }
    }

    func testCubicSplinePeriodic() {
        let x = MfArray([0.0, 1.0, 2.5, 4.0, 5.0])
        let y = MfArray([1.0, 3.0, -1.0, 0.5, 1.0])
        let new_x = MfArray([0.5, 2.0, 3.0, 4.5])
        let cubicSpline = Matft.interp1d.cubicSpline(x: x, y: y, bc_type: .periodic)
        XCTAssertEqual(cubicSpline.interpolate(x), MfArray([1.0, 3.0, -1.0, 0.5, 1.0], mftype: .Float))
        XCTAssertEqual(cubicSpline.interpolate(new_x), MfArray([2.209375, 0.36018519, -1.0287037, 0.646875], mftype: .Float))
    }

    func testLinear() {
        let x = MfArray([-1, 2, 4, 5, 7])
        let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
        let new_x = MfArray([6.0, 0.5, 3.0, 4.5, -1.0, 7.0, 2.0, 1.9])
        let interp = Matft.interp1d.linear(x: x, y: y)
        XCTAssertEqual(interp.interpolate(x), MfArray([0.2, -2.0, 9.1, 10.2, 6.4], mftype: .Float))
        XCTAssertEqual(interp.interpolate(new_x), MfArray([8.3, -0.9, 3.55, 9.65, 0.2, 6.4, -2.0, -1.92666662], mftype: .Float))
    }

    func testNearest() {
        let x = MfArray([-1, 2, 4, 5, 7])
        let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
        // the midpoint of the interval belongs to the left point
        let new_x = MfArray([6.0, 0.5, 3.0, 4.5, -1.0, 7.0, 2.0, 1.9])
        let interp = Matft.interp1d.nearest(x: x, y: y)
        XCTAssertEqual(interp.interpolate(x), MfArray([0.2, -2.0, 9.1, 10.2, 6.4], mftype: .Float))
        XCTAssertEqual(interp.interpolate(new_x), MfArray([10.2, 0.2, -2.0, 9.1, 0.2, 6.4, -2.0, -2.0], mftype: .Float))
    }

    func testPrevious() {
        let x = MfArray([-1, 2, 4, 5, 7])
        let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
        let new_x = MfArray([6.0, 0.5, 3.0, 4.5, -1.0, 7.0, 2.0, 1.9])
        let interp = Matft.interp1d.previous(x: x, y: y)
        XCTAssertEqual(interp.interpolate(x), MfArray([0.2, -2.0, 9.1, 10.2, 6.4], mftype: .Float))
        XCTAssertEqual(interp.interpolate(new_x), MfArray([10.2, 0.2, -2.0, 9.1, 0.2, 6.4, -2.0, 0.2], mftype: .Float))
    }

    func testNext() {
        let x = MfArray([-1, 2, 4, 5, 7])
        let y = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
        let new_x = MfArray([6.0, 0.5, 3.0, 4.5, -1.0, 7.0, 2.0, 1.9])
        let interp = Matft.interp1d.next(x: x, y: y)
        XCTAssertEqual(interp.interpolate(x), MfArray([0.2, -2.0, 9.1, 10.2, 6.4], mftype: .Float))
        XCTAssertEqual(interp.interpolate(new_x), MfArray([6.4, -2.0, 9.1, 10.2, 0.2, 6.4, -2.0, -2.0], mftype: .Float))
    }

    func testInterp() {
        let xp = MfArray([-1, 2, 4, 5, 7])
        let fp = MfArray([0.2, -2.0, 9.1, 10.2, 6.4])
        let x = MfArray([6.0, 0.5, -3.0, 8.0, 3.0, 1.9])

        // out of range values are fp's first and last values
        XCTAssertEqual(Matft.interp(x, xp: xp, fp: fp), MfArray([8.3, -0.9, 0.2, 6.4, 3.55, -1.92666662], mftype: .Float))
        // out of range values are left and right
        XCTAssertEqual(Matft.interp(x, xp: xp, fp: fp, left: -10, right: 10), MfArray([8.3, -0.9, -10.0, 10.0, 3.55, -1.92666662], mftype: .Float))
        // shape of x is kept
        XCTAssertEqual(Matft.interp(MfArray([[6.0, 0.5], [-3.0, 8.0]]), xp: xp, fp: fp), MfArray([[8.3, -0.9], [0.2, 6.4]], mftype: .Float))
    }

}
#endif

import XCTest
import Matft
/*
final class MatftTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        //view1()
        //view2()
        //view3()
        //view4()
        //view5()
        //view6()
        //view7()
        //view8()
        //view9()
        /*
        let a = MfArray([[2, 1, -3, 0],
                         [3, 1, 4, -5]], mftype: .Double, mforder: .Column)
        let b = MfArray([[-0.87, 1.2, 5.5134, -8.78],
                         [-0.0002, 2, 3.4, -5]], mftype: .Double, mforder: .Column)
        let c = a/b
        */
        /*
        let a = Matft.arange(start: 0, to: 8, by: 1, shape: [2,2,2])
        print(a[0~,0~,~~-1])
        print(Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]))
        let k = a[0~,0~,~~-1] - Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2])
        print(a[0~,0~,~~-1] == Matft.arange(start: 7, to: -1, by: -1, shape: [2,2,2]))*/
        /*
        let c = Matft.arange(start: 0, to: 10*10*10*10*10*10, by: 1, shape: [10,10,10,10,10,10])
        let d = c.transpose(axes: [0,3,4,2,1,5])
        let e = c.T
        
        self.measure {
            let _ = d+e
        }*/
        //XCTAssertEqual(Matft().text, "Hello, World!")
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}


func view1(){
    let a = MfArray([[[ -8,  -7,  -6,  -5],
                      [ -4,  -3,  -2,  -1]],
            
                     [[ 0,  1,  2,  3],
                      [ 4,  5,  6,  7]]], mftype: .Float)
    let aa = MfArray([[[ -8,  -7,  -6,  -5],
                       [ -4,  -3,  -2,  -1]],
    
                      [[ 0,  1,  2,  3],
                       [ 4,  5,  6,  7]]], mftype: .UInt)
    print(a)
    print(aa)
    print(aa.astype(.Float))
}

func view2(){
    let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
    print(a)
    let b = a[0~, 1~2]
    b[0~] = MfArray([999999])
    print(b)
    print(a)

}

func view3(){
    let a = Matft.arange(start: 0, to: 27, by: 1, shape: [3,3,3])
    print(a.T)
    print(a.transpose(axes: [0,2,1]))
    
    let b = Matft.arange(start: 0, to: 16, by: 1, shape: [2,4,2])
    print(b.reshape([4,4]))
    print(b.reshape([1,2,1,8]))
}

func view4(){
    let a = Matft.arange(start: 1, to: 9, by: 2, shape: [2,2])
    let b = Matft.arange(start: 1, to: 5, by: 1, shape: [2,2])
    print(a)
    print(a+b)
    print(a-b)
    print(a*b)
    print(a/b)
    
    let c = MfArray([-100,100])
    print(a+c)
}

func view5(){
    let a = Matft.arange(start: 0, to: 4, by: 1)
    print(a)
    print(Matft.math.sin(a))
    print(Matft.math.cos(a))
    print(Matft.math.tan(a))
    print(Matft.math.log(a))
    print(Matft.math.exp(a))
    let b = MfArray([0.23, -0.7, 1.7, 2.1])
    print(Matft.math.floor(b))
    print(Matft.math.ceil(b))
    print(Matft.math.nearest(b))
    
    print(Matft.math.power(bases: b, exponents: a))
}

func view6(){
    let a = MfArray([[[-5, 3, 2, 6],
                      [3, 7, -2, 0]],
        
                     [[7, 10, -9, 5],
                      [1, 1, 7, 0]]])
    print(Matft.stats.max(a))
    print(Matft.stats.min(a))
    print(Matft.stats.argmax(a))
    print(Matft.stats.argmin(a))
    
    print(Matft.stats.max(a, axis: -1))
    print(Matft.stats.min(a, axis: 0))
    print(Matft.stats.argmax(a, axis: -1))
    print(Matft.stats.argmin(a, axis: 0))
}

func view7(){
    let a = Matft.arange(start: 1, to: 5, by: 1, shape: [2,2])
    let b = Matft.arange(start: 5, to: 9, by: 1, shape: [2,2])
    print(a)
    print(b)
    print(Matft.matmul(a, b))
    print(a*&b)
    
}

func view8(){
    let coef = MfArray([[3,2],[1,2]])
    let b = MfArray([7,1])
    let ans = try! Matft.linalg.solve(coef, b: b)
    print(ans)

    
    let a = MfArray([[1,3,2],[-1,0,1],[2,3,0]])
    let ainv = try! Matft.linalg.inv(a)
    print(ainv)
    print(a*&ainv)
}

func view9(){
    
    let a = MfArray([true, false])
    print(a)
    //let b = MfArray([1, 3, true])
    //> Error!
    let b = MfArray([0, 1, -2]).astype(.Bool)
    print(b)
    
    let c = MfArray([2, 1, -3, 0])
    let d = MfArray([2.0, 1.01, -3.0, 0.0])
    
    print(c === d)
    print(c == d)
    let e = MfArray([2.0, 1.0, -3.0, 0.0])
    print(c === e)
    print(c == e)
}
*/

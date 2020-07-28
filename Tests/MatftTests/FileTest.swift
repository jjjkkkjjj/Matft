import XCTest
//@testable import Matft
import Matft


final class FileTests: XCTestCase {
    var fileurl: URL!
    
    override func setUp() {
        super.setUp()
        let thisSourceFile = URL(fileURLWithPath: #file)
        
        let thisDirectory = thisSourceFile.deletingLastPathComponent()
        let resourceURL = thisDirectory.appendingPathComponent("files")
        
        self.fileurl = resourceURL
    }
    
    func get_url(filename: String) -> URL{
        return self.fileurl!.appendingPathComponent(filename)
    }
    
    func test_loadtxt() {
        do{
            let test1 = self.get_url(filename: "test1.csv")
            let arr1: MfArray<Float>? = Matft.file.loadtxt(url: test1, delimiter: ",", encoding: .shiftJIS)
            
            XCTAssertNil(arr1)
            
            let test2 = self.get_url(filename: "test2.csv")
            let arr2: MfArray<Float>? = Matft.file.loadtxt(url: test2, delimiter: ",", encoding: .shiftJIS)
            
            XCTAssertEqual(arr2!, MfArray<Float>([[1, 2, 0],
                                           [3, 4, 2]]))
            
            let test3 = self.get_url(filename: "test3.csv")
            let arr3: MfArray<Float>? = Matft.file.loadtxt(url: test3, delimiter: ",", encoding: .shiftJIS)
            
            XCTAssertNil(arr3)
            
            let test4 = self.get_url(filename: "test4.csv")
            let arr4: MfArray<Float>? = Matft.file.loadtxt(url: test4, delimiter: ",", encoding: .shiftJIS)
            
            XCTAssertNil(arr4)
                
        }

        do{
            let test4 = self.get_url(filename: "test4.csv")
            let a1: MfArray<Float>? = Matft.file.loadtxt(url: test4, delimiter: ",", skiprows: [0, 4], encoding: .shiftJIS)
            
            XCTAssertEqual(a1!, MfArray<Float>([[1, 0, 0, 6],
                                         [3, 4, 2, 8],
                                         [2, 3, 4, 1]]))
            
            let a2: MfArray<Double>? = Matft.file.loadtxt(url: test4, delimiter: ",", skiprows: [0, 4], encoding: .shiftJIS, max_rows: 2)
            
            XCTAssertEqual(a2!, MfArray<Double>([[1, 0, 0, 6],
                                         [3, 4, 2, 8]]))
            
        }
        
    }
    
    func test_genfromtxt() {
        
        do{
            let test1 = self.get_url(filename: "test1.csv")
            let arr1: MfArray<Float>? = Matft.file.genfromtxt(url: test1, delimiter: ",", encoding: .shiftJIS)
            
            XCTAssertNil(arr1)
            
            let test2 = self.get_url(filename: "test2.csv")
            let arr2: MfArray<Float>? = Matft.file.genfromtxt(url: test2, delimiter: ",", encoding: .shiftJIS)
            
            XCTAssertEqual(arr2!, MfArray<Float>([[1, 2, 0],
                                           [3, 4, 2]]))
            /*
            let test3 = self.get_url(filename: "test3.csv")
            let arr3: MfArray<Float>? = Matft.file.genfromtxt(url: test3, delimiter: ",", encoding: .shiftJIS)
            let tmp3 = MfArray<Float>([[1, Float.nan, 0, Float.nan],
                                [3, 4, 2,  Float.nan]])
            
            // nan is handled as false.
            //let a = arr3 === tmp3
            // strange compiling... a is read as Boolean, why???
            XCTAssertEqual(arr3! === tmp3, MfArray<Bool>([[true, false, true, false],
                                                    [true, true, true, false]]))
            */
            let test4 = self.get_url(filename: "test4.csv")
            let arr4: MfArray<Float>? = Matft.file.genfromtxt(url: test4, delimiter: ",", encoding: .shiftJIS)
            
            XCTAssertNil(arr4)
                
        }

        do{
            let test4 = self.get_url(filename: "test4.csv")
            let a1: MfArray<Float>? = Matft.file.genfromtxt(url: test4, delimiter: ",", skiprows: [0, 4], encoding: .shiftJIS)
            
            XCTAssertEqual(a1!, MfArray<Float>([[1, 0, 0, 6],
                                         [3, 4, 2, 8],
                                         [2, 3, 4, 1]]))
            
            let a2 : MfArray<Double>? = Matft.file.genfromtxt(url: test4, delimiter: ",", skiprows: [0, 4], encoding: .shiftJIS, max_rows: 2)
            
            XCTAssertEqual(a2!, MfArray<Double>([[1, 0, 0, 6],
                                         [3, 4, 2, 8]]))
            
        }
        
        do{
            let test4 = self.get_url(filename: "test5.csv")
            let a1: MfArray<Float>? = Matft.file.genfromtxt(url: test4, delimiter: ",", skiprows: [0, 4], use_cols: [0, 1], encoding: .shiftJIS)
            
            XCTAssertEqual(a1!, MfArray<Float>([[1, 0],
                                         [3, 4],
                                         [2, 3]]))
            
            let a2: MfArray<Double>? = Matft.file.genfromtxt(url: test4, delimiter: ",", skiprows: [0, 4], use_cols: [3, 4], encoding: .shiftJIS, max_rows: 3)
            
            XCTAssertEqual(a2!, MfArray<Double>([[6, -3],
                                         [8, 2],
                                         [1, 1]]))
            
        }

    }
}


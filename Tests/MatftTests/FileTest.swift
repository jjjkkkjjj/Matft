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
            let arr1 = Matft.mfarray.file.loadtxt(url: test1, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr1)
            
            let test2 = self.get_url(filename: "test2.csv")
            let arr2 = Matft.mfarray.file.loadtxt(url: test2, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertEqual(arr2!, MfArray([[1, 2, 0],
                                           [3, 4, 2]], mftype: .Float))
            
            let test3 = self.get_url(filename: "test3.csv")
            let arr3 = Matft.mfarray.file.loadtxt(url: test3, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr3)
            
            let test4 = self.get_url(filename: "test4.csv")
            let arr4 = Matft.mfarray.file.loadtxt(url: test4, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr4)
                
        }

        do{
            let test4 = self.get_url(filename: "test4.csv")
            let a1 = Matft.mfarray.file.loadtxt(url: test4, delimiter: ",", mftype: .Float, skiprows: [0, 4], encoding: .shiftJIS)
            
            XCTAssertEqual(a1!, MfArray([[1, 0, 0, 6],
                                         [3, 4, 2, 8],
                                         [2, 3, 4, 1]], mftype: .Float))
            
            let a2 = Matft.mfarray.file.loadtxt(url: test4, delimiter: ",", mftype: .Double, skiprows: [0, 4], encoding: .shiftJIS, max_rows: 2)
            
            XCTAssertEqual(a2!, MfArray([[1, 0, 0, 6],
                                         [3, 4, 2, 8]], mftype: .Double))
            
        }
        
    }
    
    func test_genfromtxt() {
        do{
            let test1 = self.get_url(filename: "test1.csv")
            let arr1 = Matft.mfarray.file.genfromtxt(url: test1, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr1)
            
            let test2 = self.get_url(filename: "test2.csv")
            let arr2 = Matft.mfarray.file.genfromtxt(url: test2, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertEqual(arr2!, MfArray([[1, 2, 0],
                                           [3, 4, 2]], mftype: .Float))
            
            let test3 = self.get_url(filename: "test3.csv")
            let arr3 = Matft.mfarray.file.genfromtxt(url: test3, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            let tmp3 = MfArray([[1, Float.nan, 0, Float.nan],
                                [3, 4, 2,  Float.nan]], mftype: .Float)
            // nan is handled as false.
            XCTAssertEqual(arr3! === tmp3, MfArray([[true, false, true, false],
                                                    [true, true, true, false]]))
            
            let test4 = self.get_url(filename: "test4.csv")
            let arr4 = Matft.mfarray.file.genfromtxt(url: test4, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr4)
                
        }

        do{
            let test4 = self.get_url(filename: "test4.csv")
            let a1 = Matft.mfarray.file.genfromtxt(url: test4, delimiter: ",", mftype: .Float, skiprows: [0, 4], encoding: .shiftJIS)
            
            XCTAssertEqual(a1!, MfArray([[1, 0, 0, 6],
                                         [3, 4, 2, 8],
                                         [2, 3, 4, 1]], mftype: .Float))
            
            let a2 = Matft.mfarray.file.genfromtxt(url: test4, delimiter: ",", mftype: .Double, skiprows: [0, 4], encoding: .shiftJIS, max_rows: 2)
            
            XCTAssertEqual(a2!, MfArray([[1, 0, 0, 6],
                                         [3, 4, 2, 8]], mftype: .Double))
            
        }
        
    }
}

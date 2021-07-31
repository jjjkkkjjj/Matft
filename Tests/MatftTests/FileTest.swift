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
            let arr1 = Matft.file.loadtxt(url: test1, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr1)
            
            let test2 = self.get_url(filename: "test2.csv")
            let arr2 = Matft.file.loadtxt(url: test2, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertEqual(arr2!, MfArray([[1, 2, 0],
                                           [3, 4, 2]], mftype: .Float))
            
            let test3 = self.get_url(filename: "test3.csv")
            let arr3 = Matft.file.loadtxt(url: test3, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr3)
            
            let test4 = self.get_url(filename: "test4.csv")
            let arr4 = Matft.file.loadtxt(url: test4, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr4)
                
        }

        do{
            let test4 = self.get_url(filename: "test4.csv")
            let a1 = Matft.file.loadtxt(url: test4, delimiter: ",", mftype: .Float, skiprows: [0, 4], encoding: .shiftJIS)
            
            XCTAssertEqual(a1!, MfArray([[1, 0, 0, 6],
                                         [3, 4, 2, 8],
                                         [2, 3, 4, 1]], mftype: .Float))
            
            let a2 = Matft.file.loadtxt(url: test4, delimiter: ",", mftype: .Double, skiprows: [0, 4], encoding: .shiftJIS, max_rows: 2)
            
            XCTAssertEqual(a2!, MfArray([[1, 0, 0, 6],
                                         [3, 4, 2, 8]], mftype: .Double))
            
        }
        
    }
    
    func test_genfromtxt() {
        
        do{
            let test1 = self.get_url(filename: "test1.csv")
            let arr1 = Matft.file.genfromtxt(url: test1, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr1)
            
            let test2 = self.get_url(filename: "test2.csv")
            let arr2 = Matft.file.genfromtxt(url: test2, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertEqual(arr2!, MfArray([[1, 2, 0],
                                           [3, 4, 2]], mftype: .Float))
            
            let test3 = self.get_url(filename: "test3.csv")
            let arr3 = Matft.file.genfromtxt(url: test3, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            let tmp3 = MfArray([[1, Float.nan, 0, Float.nan],
                                [3, 4, 2,  Float.nan]], mftype: .Float)
            // nan is handled as false.
            XCTAssertEqual(arr3! === tmp3, MfArray([[true, false, true, false],
                                                    [true, true, true, false]]))
            
            let test4 = self.get_url(filename: "test4.csv")
            let arr4 = Matft.file.genfromtxt(url: test4, delimiter: ",", mftype: .Float, encoding: .shiftJIS)
            
            XCTAssertNil(arr4)
                
        }

        do{
            let test4 = self.get_url(filename: "test4.csv")
            let a1 = Matft.file.genfromtxt(url: test4, delimiter: ",", mftype: .Float, skiprows: [0, 4], encoding: .shiftJIS)
            
            XCTAssertEqual(a1!, MfArray([[1, 0, 0, 6],
                                         [3, 4, 2, 8],
                                         [2, 3, 4, 1]], mftype: .Float))
            
            let a2 = Matft.file.genfromtxt(url: test4, delimiter: ",", mftype: .Double, skiprows: [0, 4], encoding: .shiftJIS, max_rows: 2)
            
            XCTAssertEqual(a2!, MfArray([[1, 0, 0, 6],
                                         [3, 4, 2, 8]], mftype: .Double))
            
        }
        
        do{
            let test4 = self.get_url(filename: "test5.csv")
            let a1 = Matft.file.genfromtxt(url: test4, delimiter: ",", mftype: .Float, skiprows: [0, 4], use_cols: [0, 1], encoding: .shiftJIS)
            
            XCTAssertEqual(a1!, MfArray([[1, 0],
                                         [3, 4],
                                         [2, 3]], mftype: .Float))
            
            let a2 = Matft.file.genfromtxt(url: test4, delimiter: ",", mftype: .Double, skiprows: [0, 4], use_cols: [3, 4], encoding: .shiftJIS, max_rows: 3)
            
            XCTAssertEqual(a2!, MfArray([[6, -3],
                                         [8, 2],
                                         [1, 1]], mftype: .Double))
            
        }

    }
    
    func test_savetxt(){
        do{
            let a = MfArray([[1, 0, 0, 6],
                             [3, 4, 2, 8],
                             [2, 3, 4, 1]])
            let test_w1 = self.get_url(filename: "test_w1.csv")
            Matft.file.savetxt(url: test_w1, mfarray: a, delimiter: ",")
            
            let arr1 = Matft.file.loadtxt(url: test_w1, delimiter: ",", mftype: .Int)
            XCTAssertEqual(a, arr1)
        }
        
        do{
            let a = MfArray([2.3, 2.0, -0.3, 7.1, -9.1, 3.3, 2.5])
            let test_w2 = self.get_url(filename: "test_w2.csv")
            Matft.file.savetxt(url: test_w2, mfarray: a, delimiter: ",")
            
            let arr2 = Matft.file.loadtxt(url: test_w2, delimiter: ",", mftype: .Double)
            XCTAssertEqual(a, arr2)
        }
        
        do{
            let a = MfArray([[0.48119989, 0.43105108, 0.31772771, 0.43124228, 0.7316661 ],
                             [0.06785366, 0.92990358, 0.36221086, 0.21251478, 0.58757896],
                             [0.90790159, 0.53436599, 0.26298621, 0.1055088 , 0.76278012],
                             [0.63767623, 0.21296142, 0.89174772, 0.34907663, 0.55014662],
                             [0.05292474, 0.25471397, 0.66266674, 0.46161502, 0.79784103]], mftype: .Float)
            let test_w3 = self.get_url(filename: "test_w3.csv")
            Matft.file.savetxt(url: test_w3, mfarray: a, delimiter: ",")
            
            let arr3 = Matft.file.loadtxt(url: test_w3, delimiter: ",", mftype: .Float)
            XCTAssertEqual(a, arr3)
        }
    }
}

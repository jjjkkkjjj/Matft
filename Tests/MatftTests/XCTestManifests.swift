import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MatftTests.allTests),
        //testCase(ArithmeticPefTests.allTests)
    ]
}
#endif

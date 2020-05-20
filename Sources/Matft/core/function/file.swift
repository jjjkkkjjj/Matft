//
//  File.swift
//  
//
//  Created by AM19A0 on 2020/05/12.
//

import Foundation

extension Matft.mfarray.file{
    /**
        Load file from given path and create mfarray. If the file is not loaded, return nil.
       - parameters:
           - mfarray: mfarray
    */
    public static func loadtxt(url: URL, delimiter: Character, mftype: MfType = .Float, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray?{

        guard let parser = _TxtParser(url, delimiter, encoding, removeBlank) else { return nil }

        switch MfType.storedType(mftype) {
        case .Float:
            return _load(parser: parser, type: Float.self, mftype, skiprows, use_cols, max_rows)
            
        case .Double:
            return _load(parser: parser, type: Double.self, mftype, skiprows, use_cols, max_rows)
        }
    }
    public static func loadtxt(path: String, delimiter: Character, mftype: MfType = .Float, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray?{
        
        guard let parser = _TxtParser(path, delimiter, encoding, removeBlank) else { return nil }
        
        switch MfType.storedType(mftype) {
        case .Float:
            return _load(parser: parser, type: Float.self, mftype, skiprows, use_cols, max_rows)
            
        case .Double:
            return _load(parser: parser, type: Double.self, mftype, skiprows, use_cols, max_rows)
        }
    }
    
    public static func genfromtxt<T: MfStorable>(url: URL, delimiter: Character, fillnan: T, mftype: MfType = .Float, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray?{
        
        guard let parser = _TxtParser(url, delimiter, encoding, removeBlank) else { return nil }
        
        switch MfType.storedType(mftype) {
        case .Float:
            return _gen(parser: parser, fillnan: Float.from(fillnan), mftype, skiprows, use_cols, max_rows)
            
        case .Double:
            return _gen(parser: parser, fillnan: Double.from(fillnan), mftype, skiprows, use_cols, max_rows)
        }
    }
    public static func genfromtxt(url: URL, delimiter: Character, mftype: MfType = .Float, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray?{
        
        guard let parser = _TxtParser(url, delimiter, encoding, removeBlank) else { return nil }
        
        switch MfType.storedType(mftype) {
        case .Float:
            return _gen(parser: parser, fillnan: Float.nan, mftype, skiprows, use_cols, max_rows)
            
        case .Double:
            return _gen(parser: parser, fillnan: Double.nan, mftype, skiprows, use_cols, max_rows)
        }
    }
    public static func genfromtxt<T: MfStorable>(path: String, delimiter: Character, fillnan: T, mftype: MfType = .Float, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray?{
        
        guard let parser = _TxtParser(path, delimiter, encoding, removeBlank) else { return nil }
        
        switch MfType.storedType(mftype) {
        case .Float:
            return _gen(parser: parser, fillnan: Float.from(fillnan), mftype, skiprows, use_cols, max_rows)
            
        case .Double:
            return _gen(parser: parser, fillnan: Double.from(fillnan), mftype, skiprows, use_cols, max_rows)
        }
    }
    public static func genfromtxt(path: String, delimiter: Character, mftype: MfType = .Float, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray?{
        
        guard let parser = _TxtParser(path, delimiter, encoding, removeBlank) else { return nil }
        
        switch MfType.storedType(mftype) {
        case .Float:
            return _gen(parser: parser, fillnan: Float.nan, mftype, skiprows, use_cols, max_rows)
            
        case .Double:
            return _gen(parser: parser, fillnan: Double.nan, mftype, skiprows, use_cols, max_rows)
        }
    }

}

fileprivate func _load<T: MfStorable>(parser: _TxtParser, type: T.Type, _ mftype: MfType = .Float, _ skiprows: [Int]? = nil, _ use_cols: [Int]? = nil, _ max_rows: Int? = nil) -> MfArray?{
    /*
    cannot load ,\n
    e.g.) test.csv
    1,2,0,
    3,4,2
    >>> np.loadtxt('test.csv', delimiter=',')
    ValueError: could not convert string to float:
    
    1,2,0,
    3,4,2,
    >>> np.loadtxt('test.csv', delimiter=',')
    ValueError: could not convert string to float:
    
    1,2,0
    3,4,2
    >>> np.loadtxt('test.csv', delimiter=',')
    array([[1., 2., 0.],
           [3., 4., 2.]])
    */
    guard let lines = parser.load() else {
        return nil
    }
    
    var ret: [[T]] = []
    for (row, line) in lines.enumerated(){
        if skiprows?.contains(row) ?? false{
            continue
        }
        if (max_rows ?? -1) == ret.count{
            break
        }
        let arr_str = line.split(separator: parser.delimiter, omittingEmptySubsequences: false)
        
        var ret_line: [T] = []
        for (col, str) in arr_str.enumerated(){
            if !(use_cols?.contains(col) ?? true){
                continue
            }
            
            guard let val = T.from(str) else{
                print("could not convert string to float: \"\(str)\"")
                return nil
            }
            
            ret_line += [val]
        }
        ret += [ret_line]
    }
    
    //squeeze if one line only
    return MfArray(ret, mftype: mftype).squeeze()
}

fileprivate func _gen<T: MfStorable>(parser: _TxtParser, fillnan: T, _ mftype: MfType = .Float, _ skiprows: [Int]? = nil, _ use_cols: [Int]? = nil, _ max_rows: Int? = nil) -> MfArray?{
    /*
    cannot load imbalance delimiter
    e.g.) test.csv
    1,2,0,
    3,4,2
    >>> np.genfromtxt('test.csv', delimiter=',')
    ValueError: Some errors were detected !
    Line #2 (got 3 columns instead of 4)
    
    1,2,0,
    3,4,2,
    >>> np.genfromtxt('test.csv', delimiter=',')
    array([[ 1.,  2.,  0., nan],
           [ 3.,  4.,  2., nan]])
    */
    
    guard let lines = parser.load() else {
        return nil
    }
    
    
    var ret: [[T]] = []
    var col_num = -1
    for (row, line) in lines.enumerated(){
        if skiprows?.contains(row) ?? false{
            continue
        }
        if (max_rows ?? -1) == ret.count{
            break
        }
        let arr_str = line.split(separator: parser.delimiter, omittingEmptySubsequences: false)
        
        // check column number
        if use_cols == nil{
            col_num = col_num == -1 ? arr_str.count : col_num
            if arr_str.count != col_num{
                print("Some errors were detected !\nLine #\(row) (got \(arr_str.count) columns instead of \(col_num)")
                return nil
            }
        }
        
        var ret_line: [T] = []
        for (col, str) in arr_str.enumerated(){
            if !(use_cols?.contains(col) ?? true){
                continue
            }
            
            if str == ""{ // nan
                ret_line += [fillnan]
            }
            else if let val = T.from(str){ // value
                ret_line += [val]
            }
            else{
                print("could not convert string to float: \"\(str)\"")
                return nil
            }
            
            
        }
        ret += [ret_line]
    }
    
    //squeeze if one line only
    return MfArray(ret, mftype: mftype).squeeze()
}


fileprivate class _TxtParser{
    let url: URL
    let delimiter: Character
    let encoding: String.Encoding
    let removeBlank: Bool
    
    let file: FileHandle
    
    init?(_ path: String, _ delimiter: Character = ",", _ encoding: String.Encoding = .utf8, _ removeBlank: Bool = true){
        let url = URL(fileURLWithPath: path)
        // check path and get file from path
        guard let file = try? FileHandle(forReadingFrom: url) else{
            print("Invalid path: \(path)")
            return nil
        }
        
        //initialize
        self.url = url
        self.delimiter = delimiter
        self.encoding = encoding
        self.removeBlank = removeBlank
        
        self.file = file
    }
    init?(_ url: URL, _ delimiter: Character = ",", _ encoding: String.Encoding = .utf8, _ removeBlank: Bool = true){
        guard let file = try? FileHandle(forReadingFrom: url) else{
            print("Invalid url: \(url)")
            return nil
        }
        
        //initialize
        self.url = url
        self.delimiter = delimiter
        self.encoding = encoding
        self.removeBlank = removeBlank
        
        self.file = file
    }
    
    
    deinit {
        self.file.closeFile()
    }
    
    func load() -> [String]?{
        let contentData = self.file.readDataToEndOfFile()
        // convert byte to string
        guard var contentString = String(data: contentData, encoding: self.encoding) else{
            print("cannot load. You may pass invalid encoding")
            return nil
        }
        
        if self.removeBlank{// remove white space. e.g.) ,3 4, -> ,34,
            contentString = contentString.replacingOccurrences(of: " ", with: "")
        }
        
        var lines = contentString.components(separatedBy: .newlines)
        
        // remove empty line
        lines = lines.filter{ !$0.isEmpty }
        
        return lines
    }
    
    func export(){
        
    }
}

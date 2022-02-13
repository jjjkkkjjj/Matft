//
//  file+static.swift
//  
//
//  Created by Junnosuke Kado on 2022/02/13.
//

import Foundation

extension Matft.file{

    /// Load file from given path and create mfarray. If the file is not loaded, return nil.
    /// - parameters:
    ///   - url: URL
    ///   - mfarray: mfarray
    ///   - delimiter:  The character separating columns
    ///   - mftype: MfType
    ///   - skiprows: (Optional) The row number to slip
    ///   - use_cols: (Optional) [Int] The column number to parse
    ///   - encoding:  Encoding format
    ///   - max_rows: (Optional) The maximum row number
    ///   - removeBlank: Whether to remove blank
    /// - Returns: Loaded mfarray
    public static func loadtxt<T: MfTypeUsable>(url: URL, delimiter: Character, mftype: T.Type, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray<T>?{

        guard let parser = _TxtParser(url, delimiter, encoding, removeBlank) else { return nil }

        return _load(parser: parser, type: T.self, skiprows, use_cols, max_rows)
    }
    
    
    /// Load file from given path and create mfarray. If the file is not loaded, return nil.
    /// - parameters:
    ///   - path: The file path to load
    ///   - mfarray: mfarray
    ///   - delimiter:  The character separating columns
    ///   - mftype: MfType
    ///   - skiprows: (Optional) The row number to slip
    ///   - use_cols: (Optional) [Int] The column number to parse
    ///   - encoding:  Encoding format
    ///   - max_rows: (Optional) The maximum row number
    ///   - removeBlank: Whether to remove blank
    /// - Returns: Loaded mfarray
    public static func loadtxt<T: MfTypeUsable>(path: String, delimiter: Character, mftype: T.Type, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray<T>?{
        
        guard let parser = _TxtParser(path, delimiter, encoding, removeBlank) else { return nil }
        
        return _load(parser: parser, type: T.self, skiprows, use_cols, max_rows)
    }
    
    /// Load file with missing values from given path and create mfarray. If the file is not loaded, return nil.
    /// - parameters:
    ///   - url: URL
    ///   - mfarray: mfarray
    ///   - delimiter:  The character separating columns
    ///   - mftype: MfType
    ///   - skiprows: (Optional) The row number to slip
    ///   - use_cols: (Optional) [Int] The column number to parse
    ///   - encoding:  Encoding format
    ///   - max_rows: (Optional) The maximum row number
    ///   - removeBlank: Whether to remove blank
    /// - Returns: generated mfarray
    public static func genfromtxt<T: MfTypeUsable>(url: URL, delimiter: Character, fillnan: T, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray<T>?{
        
        guard let parser = _TxtParser(url, delimiter, encoding, removeBlank) else { return nil }
        
        return _gen(parser: parser, fillnan: T.StoredType.from(fillnan), skiprows, use_cols, max_rows)
    }
    
    /// Load file with missing values from given path and create mfarray. If the file is not loaded, return nil.
    /// - parameters:
    ///   - url: URL
    ///   - mfarray: mfarray
    ///   - delimiter:  The character separating columns
    ///   - mftype: MfType
    ///   - skiprows: (Optional) The row number to slip
    ///   - use_cols: (Optional) [Int] The column number to parse
    ///   - encoding:  Encoding format
    ///   - max_rows: (Optional) The maximum row number
    ///   - removeBlank: Whether to remove blank
    /// - Returns: generated mfarray
    public static func genfromtxt<T: MfTypeUsable>(url: URL, delimiter: Character, mftype: T.Type, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray<T>?{
        
        guard let parser = _TxtParser(url, delimiter, encoding, removeBlank) else { return nil }
        
        return _gen(parser: parser, fillnan: T.StoredType.nan, skiprows, use_cols, max_rows)
    }
    
    /// Load file with missing values from given path and create mfarray. If the file is not loaded, return nil.
    /// - parameters:
    ///   - path: The file path to load
    ///   - mfarray: mfarray
    ///   - delimiter:  The character separating columns
    ///   - mftype: MfType
    ///   - skiprows: (Optional) The row number to slip
    ///   - use_cols: (Optional) [Int] The column number to parse
    ///   - encoding:  Encoding format
    ///   - max_rows: (Optional) The maximum row number
    ///   - removeBlank: Whether to remove blank
    /// - Returns: generated mfarray
    public static func genfromtxt<T: MfTypeUsable>(path: String, delimiter: Character, fillnan: T, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray<T>?{
        
        guard let parser = _TxtParser(path, delimiter, encoding, removeBlank) else { return nil }
        
        return _gen(parser: parser, fillnan: T.StoredType.from(fillnan), skiprows, use_cols, max_rows)
    }
    

    /// Load file with missing values from given path and create mfarray. If the file is not loaded, return nil.
    /// - parameters:
    ///   - path: The file path to load
    ///   - mfarray: mfarray
    ///   - delimiter:  The character separating columns
    ///   - mftype: MfType
    ///   - skiprows: (Optional) The row number to slip
    ///   - use_cols: (Optional) [Int] The column number to parse
    ///   - encoding:  Encoding format
    ///   - max_rows: (Optional) The maximum row number
    ///   - removeBlank: Whether to remove blank
    /// - Returns: generated mfarray
    public static func genfromtxt<T: MfTypeUsable>(path: String, delimiter: Character, mftype: T.Type, skiprows: [Int]? = nil, use_cols: [Int]? = nil, encoding: String.Encoding = .utf8, max_rows: Int? = nil, removeBlank: Bool = true) -> MfArray<T>?{
        
        guard let parser = _TxtParser(path, delimiter, encoding, removeBlank) else { return nil }
        
        return _gen(parser: parser, fillnan: T.StoredType.nan, skiprows, use_cols, max_rows)
    }
    

    /// Save file to a given url
    /// - parameters:
    ///   - url: The file URL to save
    ///   - mfarray: mfarray
    ///   - delimiter:  The character separating columns
    ///   - newline:  The newline character
    ///   - encoding:  Encoding format
    public static func savetxt<T: MfTypeUsable>(url: URL, mfarray: MfArray<T>, delimiter: Character, newline: Character = "\n", encoding: String.Encoding = .utf8){
        _save(url: url, mfarray: mfarray, delimiter: delimiter, newline: newline, encoding: encoding)
    }
    
    /// Save file to a given url
    /// - parameters:
    ///   - path: The file path to save
    ///   - mfarray: mfarray
    ///   - delimiter:  The character separating columns
    ///   - newline:  The newline character
    ///   - encoding:  Encoding format
    public static func savetxt<T: MfTypeUsable>(path: String, mfarray: MfArray<T>, delimiter: Character, newline: Character = "\n", encoding: String.Encoding = .utf8){
        let url = URL(fileURLWithPath: path)
        _save(url: url, mfarray: mfarray, delimiter: delimiter, newline: newline, encoding: encoding)
    }
}

fileprivate func _load<T: MfTypeUsable>(parser: _TxtParser, type: T.Type, _ skiprows: [Int]? = nil, _ use_cols: [Int]? = nil, _ max_rows: Int? = nil) -> MfArray<T>?{
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
            
            guard let val = T.from(String(str)) else{
                print("could not convert string to float: \"\(str)\"")
                return nil
            }
            
            ret_line += [val]
        }
        ret += [ret_line]
    }
    
    //squeeze if one line only
    return MfArray(ret).squeeze()
}


fileprivate func _gen<T: MfTypeUsable>(parser: _TxtParser, fillnan: T.StoredType, _ skiprows: [Int]? = nil, _ use_cols: [Int]? = nil, _ max_rows: Int? = nil) -> MfArray<T>?{
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
    
    
    var ret: [[T.StoredType]] = []
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
        
        var ret_line: [T.StoredType] = []
        for (col, str) in arr_str.enumerated(){
            if !(use_cols?.contains(col) ?? true){
                continue
            }
            
            if str == ""{ // nan
                ret_line += [fillnan]
            }
            else if let val = T.StoredType.from(String(str)){ // value
                ret_line += [val]
            }
            else{
                print("could not convert string to float: \"\(str)\"")
                return nil
            }
            
            
        }
        ret += [ret_line]
    }
     
    // check shape
    if ret.count == 0 {
        return nil
    }
    
    var ret_shape = [ret.count, ret[0].count]
    for l in ret{
        precondition(l.count == ret_shape[1], "Invalid file! Unsame column number!")
    }
    
    var flatten = ret.flatMap{ $0 }
    precondition(shape2size(&ret_shape) == flatten.count, "Invalid file!")
    
    let newdata = MfData(T.self, storedFlattenArray: &flatten)
    
    let newstructure = MfStructure(shape: ret_shape, mforder: .Row)
    
    //squeeze if one line only
    return MfArray(mfdata: newdata, mfstructure: newstructure).squeeze()
}

fileprivate func _save<T: MfTypeUsable>(url: URL, mfarray: MfArray<T>, delimiter: Character, newline: Character = "\n", encoding: String.Encoding = .utf8){
    precondition(mfarray.ndim <= 2, "mfarray must be 1d or 2d, but got \(mfarray.ndim)d")
    let mfarray = mfarray.ndim == 1 ? mfarray.expand_dims(axis: 0) : mfarray
    
    let delimiter = String(delimiter)
    let stride = mfarray.shape[1]
    let flattenarray: [T] = mfarray.toFlattenArray()
    
    let contents: [String]
    if let flattenarray = flattenarray as? [Bool]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [UInt8]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [UInt16]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [UInt32]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [UInt64]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [UInt]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [Int8]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [Int16]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [Int32]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [Int64]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [Int]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [Float]{
        contents = flattenarray.map{ String($0) }
    }
    else if let flattenarray = flattenarray as? [Double]{
        contents = flattenarray.map{ String($0) }
    }
    else{
        fatalError("Unsupported types")
    }
    
    var contentString = ""
    for i in 0..<(mfarray.size / stride){
        contentString += contents[i*stride..<(i+1)*stride].joined(separator: delimiter) + String(newline)
    }

    try? contentString.write(to: url, atomically: false, encoding: encoding)
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
}

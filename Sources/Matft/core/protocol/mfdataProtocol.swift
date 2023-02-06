//
//  File.swift
//  
//
//  Created by AM19A0 on 2023/02/06.
//

import Foundation
import CoreML

public protocol MfDataBasable {}

extension MfData: MfDataBasable{}

@available(macOS 12.0, *)
extension MLShapedArray: MfDataBasable{}

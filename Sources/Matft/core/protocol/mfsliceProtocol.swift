//
//  mfsliceProtocol.swift
//  Matft
//
//  Created by AM19A0 on 2020/03/13.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

public protocol MfSubscriptable{}

extension Int: MfSubscriptable{}
extension MfSlice: MfSubscriptable{}

public enum SubscriptOps: MfSubscriptable{
    case newaxis
    case all
    case reverse
}

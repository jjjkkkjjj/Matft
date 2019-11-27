//
//  common_utils.swift
//  MatftSample
//
//  Created by AM19A0 on 2019/11/07.
//  Copyright © 2019 jkado. All rights reserved.
//

import Foundation

extension Collection where Index: Comparable {
    subscript(back i: Int) -> Iterator.Element {
        let backBy = i + 1
        return self[self.index(self.endIndex, offsetBy: -backBy)]
    }
}

extension Array where Element: Equatable {
    mutating func remove(value: Element) {
        if let i = self.firstIndex(of: value) {
            self.remove(at: i)
        }
    }
}


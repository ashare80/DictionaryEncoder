//
//  Copyright (c) 2022. Adam Share
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// A coding key from a string or int value that can be used with any type.
struct AnyCodingKey: CodingKey {
    var intValue: Int?
    var stringValue: String

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.init(intValue)
    }

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init(_ intValue: Int) {
        self.intValue = intValue
        stringValue = String(intValue)
    }
}

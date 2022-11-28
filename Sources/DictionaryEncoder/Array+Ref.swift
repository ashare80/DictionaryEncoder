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

extension Array {
    /// Provides a mutable reference to an Array stored elsewhere
    struct Ref {
        var captured: ((inout Array) -> Void) -> Void

        public var count: Int {
            var count = 0
            captured { array in
                count = array.count
            }
            return count
        }

        public var endIndex: Index {
            var endIndex: Index = 0
            captured { array in
                endIndex = array.endIndex
            }
            return endIndex
        }

        public func insert(_ element: Element, at index: Index) {
            captured { array in
                array.insert(element, at: index)
            }
        }

        public func replace(_ element: Element, at index: Index) {
            captured { array in
                array[index] = element
            }
        }

        public func append(_ element: Element) {
            captured { array in
                array.append(element)
            }
        }
    }
}

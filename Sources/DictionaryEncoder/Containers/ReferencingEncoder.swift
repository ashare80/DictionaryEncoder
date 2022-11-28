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

extension DictionaryEncoder {
    /// Super encoder writes back into referenced encoder on deinit
    ///
    /// While encoding a class a super class might have a different expectation for an encoder.
    /// Since an encoder can only be one type of container this new container can be created and passed to super.
    /// When it is done it will write back to the initial encoder at the key or index of the original container.
    ///
    /// See detailed explaination of this special encoding case: [Writing Encoders and Decoders](https://forums.swift.org/t/writing-encoders-and-decoders-different-question/10232/5)
    class ReferencingEncoder: SingleValueContainer {
        private enum Reference {
            /// Referencing a specific index in an array container.
            case array(Array.Ref, Int)

            /// Referencing a specific key in a dictionary container.
            case dictionary(Dictionary.Ref, String)
        }

        private let encoder: SingleValueContainer
        private let reference: Reference

        init(encoder: SingleValueContainer, at index: Int, container: Array.Ref) {
            self.encoder = encoder
            reference = .array(container, index)
            super.init(codingPath: encoder.codingPath, options: encoder.options, userInfo: encoder.userInfo)

            codingPath.append(AnyCodingKey(index))
        }

        init(encoder: SingleValueContainer, at key: CodingKey, container: Dictionary.Ref) {
            self.encoder = encoder
            reference = .dictionary(container, key.stringValue)
            super.init(codingPath: encoder.codingPath, options: encoder.options, userInfo: encoder.userInfo)

            codingPath.append(key)
        }

        override var canEncodeNewValue: Bool {
            // With a regular encoder, the storage and coding path grow together.
            // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
            // We have to take this into account.
            storage.count == codingPath.count - encoder.codingPath.count - 1
        }

        deinit {
            let value: Any
            switch storage.count {
            case 0:
                value = [String: Any]()
            case 1:
                value = storage.removeLast().containedValue()
            default:
                fatalError("encoding at coding path \(codingPath) deallocated with multiple containers on stack: \(storage)")
            }

            switch reference {
            case let .array(array, index):
                array.insert(value, at: index)

            case let .dictionary(dictionary, key):
                dictionary.updateValue(value, forKey: key)
            }
        }
    }
}

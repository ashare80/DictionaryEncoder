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
    /// Encodes values and stores them in an `Dictionary`.
    ///
    /// Created when a single values nests multiple keyed values inside. E.g. struct, class, Dictionary and enum.
    /// Each call to encode will store the keyed value in a `Dictionary`that will be provided as a reference to the `Encoder`'s storage.
    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        public var encoder: SingleValueContainer
        public var codingPath: [CodingKey]
        public var container: Dictionary.Ref

        public mutating func encodeNil(forKey key: Key) throws { updateValue(NSNull(), forKey: key) }
        mutating func encode(_ value: Bool, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: String, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: Double, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: Float, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: Int, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: Int8, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: Int16, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: Int32, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: Int64, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: UInt, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: UInt8, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: UInt16, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: UInt32, forKey key: Key) throws { updateValue(value, forKey: key) }
        mutating func encode(_ value: UInt64, forKey key: Key) throws { updateValue(value, forKey: key) }

        public mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.codingPath.append(key)
            defer { encoder.codingPath.removeLast() }
            updateValue(try encoder.encode(value).containedValue(), forKey: key)
        }

        func updateValue<Value>(_ value: Value, forKey key: Key) {
            container.updateValue(value, forKey: key.stringValue)
        }

        public mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            codingPath.append(key)
            defer { codingPath.removeLast() }

            var keyedContainer: [String: Any] = [:]
            container.updateValue(keyedContainer, forKey: key.stringValue)

            let nestedContainer = Dictionary.Ref { [container] update in
                container.updateValue([:], forKey: key.stringValue) // Avoid copy on write as we'll have multiple references.
                update(&keyedContainer)
                container.updateValue(keyedContainer, forKey: key.stringValue)
            }

            return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder,
                                                                    codingPath: codingPath,
                                                                    container: nestedContainer))
        }

        public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            codingPath.append(key); defer { codingPath.removeLast() }

            var unkeyedContainer: [Any] = []
            container.updateValue(unkeyedContainer, forKey: key.stringValue)

            let nestedContainer = Array.Ref { [container] update in
                container.updateValue([:], forKey: key.stringValue) // Avoid copy on write as we'll have multiple references.
                update(&unkeyedContainer)
                container.updateValue(unkeyedContainer, forKey: key.stringValue)
            }

            return UnkeyedContainer(encoder: encoder, codingPath: codingPath, container: nestedContainer)
        }

        public mutating func superEncoder() -> Encoder {
            ReferencingEncoder(encoder: encoder, at: AnyCodingKey("super"), container: container)
        }

        public mutating func superEncoder(forKey key: Key) -> Encoder {
            ReferencingEncoder(encoder: encoder, at: key, container: container)
        }
    }
}

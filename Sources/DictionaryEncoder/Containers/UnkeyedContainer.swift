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
    /// Encodes values and stores them in an `Array`.
    ///
    /// An `UnkeyedContainer` is requested by an `Encodable` type to store multiple elements
    /// Each call to encode will store the keyed value in an `Array`that will be provided as a reference to the `Encoder`'s storage.
    ///
    /// While typically created to encode an Array, some values may choose to request an unkeyed container to encode into.
    ///
    /// Example:
    ///
    ///     class Point: Encodable {
    ///       var x: Double
    ///       var y: Double
    ///
    ///       func encode(to encoder: Encoder) throws {
    ///         var container = encoder.unkeyedContainer()
    ///         try container.encode(x)
    ///         try container.encode(y)
    ///       }
    ///     }
    struct UnkeyedContainer: UnkeyedEncodingContainer {
        public var encoder: SingleValueContainer
        public var codingPath: [CodingKey]
        public var container: Array.Ref

        /// The number of elements encoded into the container.
        public var count: Int {
            container.count
        }

        public mutating func encodeNil() throws { append(NSNull()) }
        mutating func encode(_ value: Bool) throws { append(value) }
        mutating func encode(_ value: String) throws { append(value) }
        mutating func encode(_ value: Double) throws { append(value) }
        mutating func encode(_ value: Float) throws { append(value) }
        mutating func encode(_ value: Int) throws { append(value) }
        mutating func encode(_ value: Int8) throws { append(value) }
        mutating func encode(_ value: Int16) throws { append(value) }
        mutating func encode(_ value: Int32) throws { append(value) }
        mutating func encode(_ value: Int64) throws { append(value) }
        mutating func encode(_ value: UInt) throws { append(value) }
        mutating func encode(_ value: UInt8) throws { append(value) }
        mutating func encode(_ value: UInt16) throws { append(value) }
        mutating func encode(_ value: UInt32) throws { append(value) }
        mutating func encode(_ value: UInt64) throws { append(value) }

        /// Encodes the type using the single value container encoder.
        ///
        /// Calling encode on a primitive type will attempt to encode the same type
        /// causing infinite recursion so we handle those cases individually.
        public mutating func encode<T: Encodable>(_ value: T) throws {
            encoder.codingPath.append(AnyCodingKey(count))
            defer { encoder.codingPath.removeLast() }

            append(try encoder.encode(value).containedValue())
        }

        func append<Value>(_ value: Value) {
            container.append(value)
        }

        public mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            codingPath.append(AnyCodingKey(count))
            defer { codingPath.removeLast() }

            var keyContainer: [String: Any] = [:]
            let index = container.endIndex
            container.append(keyContainer)

            let nestedContainer = Dictionary.Ref { [container] update in
                container.replace([:], at: index) // Avoid copy on write as we'll have multiple references.
                update(&keyContainer)
                container.replace(keyContainer, at: index)
            }

            return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder,
                                                                    codingPath: codingPath,
                                                                    container: nestedContainer))
        }

        public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            codingPath.append(AnyCodingKey(count))
            defer { codingPath.removeLast() }

            var unkeyedContainer: [Any] = []
            let index = container.endIndex
            container.append(unkeyedContainer)

            let nestedContainer = Array.Ref { [container] update in
                container.replace([], at: index) // Avoid copy on write as we'll have multiple references.
                update(&unkeyedContainer)
                container.replace(unkeyedContainer, at: index)
            }

            return UnkeyedContainer(encoder: encoder,
                                    codingPath: codingPath,
                                    container: nestedContainer)
        }

        public mutating func superEncoder() -> Encoder {
            ReferencingEncoder(encoder: encoder,
                               at: count,
                               container: container)
        }
    }
}

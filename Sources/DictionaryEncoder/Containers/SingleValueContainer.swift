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
    typealias Dictionary = [String: Any]
    typealias Array = [Any]

    /// Acts as both the `Encoder` and the `SingleValueEncodingContainer`.
    ///
    /// The encoder contains a stack of `Container` types that act as the internal storage representation of the provided containers to the `Encodable`.
    /// As nested values are encoded they push to the stack and when they are done encoding they are popped and stored in the previous container.
    /// When all values have been encoded the last container on the stack will be the single value representation of starting value.
    class SingleValueContainer: Encoder, SingleValueEncodingContainer {
        var options: Options

        /// The encoder's storage.
        var storage: [Container] = []

        /// The path to the current point in encoding.
        public var codingPath: [CodingKey]

        /// Contextual user-provided information for use during encoding.
        public var userInfo: [CodingUserInfoKey: Any]

        /// Initializes `self` with the given top-level encoder options.
        init(codingPath: [CodingKey] = [], options: Options, userInfo: [CodingUserInfoKey: Any] = [:]) {
            self.codingPath = codingPath
            self.options = options
            self.userInfo = userInfo
        }

        /// Returns whether a new element can be encoded at this coding path.
        ///
        /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
        ///
        /// Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        /// At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        /// If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        ///
        /// This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        /// Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        var canEncodeNewValue: Bool {
            storage.count == codingPath.count
        }

        public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
            var index: Int
            if canEncodeNewValue {
                index = storage.endIndex
                storage.append(Container(containerType: .keyed(keyedBy)))
            } else {
                index = storage.endIndex - 1
                guard case .keyed = storage.last?.containerType else {
                    preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
                }
            }

            let container = Dictionary.Ref { container in
                container(&self.storage[index].dictionary)
            }

            return KeyedEncodingContainer(KeyedContainer<Key>(encoder: self, codingPath: codingPath, container: container))
        }

        public func unkeyedContainer() -> UnkeyedEncodingContainer {
            var index: Int
            if canEncodeNewValue {
                index = storage.endIndex
                storage.append(Container(containerType: .unkeyed(index)))
            } else {
                index = storage.endIndex - 1
                guard case .unkeyed = storage.last?.containerType else {
                    preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
                }
            }

            let container = Array.Ref { container in
                container(&self.storage[index].array)
            }

            return UnkeyedContainer(encoder: self, codingPath: codingPath, container: container)
        }

        public func singleValueContainer() -> SingleValueEncodingContainer {
            self
        }

        private func assertCanEncodeNewValue() {
            precondition(canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
        }

        public func encodeNil() throws {
            assertCanEncodeNewValue()
            storage.append(Container())
        }

        func encode(_ value: Bool) throws { append(value) }
        func encode(_ value: String) throws { append(value) }
        func encode(_ value: Double) throws { append(value) }
        func encode(_ value: Float) throws { append(value) }
        func encode(_ value: Int) throws { append(value) }
        func encode(_ value: Int8) throws { append(value) }
        func encode(_ value: Int16) throws { append(value) }
        func encode(_ value: Int32) throws { append(value) }
        func encode(_ value: Int64) throws { append(value) }
        func encode(_ value: UInt) throws { append(value) }
        func encode(_ value: UInt8) throws { append(value) }
        func encode(_ value: UInt16) throws { append(value) }
        func encode(_ value: UInt32) throws { append(value) }
        func encode(_ value: UInt64) throws { append(value) }

        /// Encodes the type using the single value container encoder.
        ///
        /// Calling encode on a primitive type will attempt to encode the same type
        /// causing infinite recursion so we handle those cases individually.
        func encode<T: Encodable>(_ value: T) throws {
            assertCanEncodeNewValue()
            try storage.append(encode(value))
        }

        func append(_ value: Any) {
            assertCanEncodeNewValue()
            storage.append(Container(value: value))
        }

        func encode<T: Encodable>(_ value: T) throws -> Container {
            guard options.shouldEncode(value) else {
                return Container(value: value)
            }

            let depth = storage.count
            do {
                try value.encode(to: self)
            } catch {
                if storage.count > depth {
                    _ = storage.removeLast()
                }

                throw error
            }

            // The top container should be a new container.
            guard storage.count > depth else {
                return Container(containerType: .keyed(T.self))
            }

            return storage.removeLast()
        }
    }

    struct Container {
        var containerType: ContainerType = .singleValue
        var value: Any = NSNull()
        var array: [Any] = []
        var dictionary: [String: Any] = [:]

        func containedValue() -> Any {
            switch containerType {
            case .keyed:
                return dictionary
            case .unkeyed:
                return array
            case .singleValue:
                return value
            }
        }

        enum ContainerType {
            case keyed(Any)
            case unkeyed(Int)
            case singleValue
        }
    }
}

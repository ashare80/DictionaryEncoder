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

import Combine
import Foundation

/// Errors from `DictionaryEncoder`
public enum DictionaryEncoderError: LocalizedError {
    /// The type was not encoded to a keyed container so a dictionary could not be returned.
    case notKeyedContainer(Any)

    public var errorDescription: String? {
        switch self {
        case let .notKeyedContainer(value):
            return "\(value) does not encode to a keyed container."
        }
    }
}

/// Top level encoder that enables encoding instances into a `Dictionary`.
///
/// Encoder has been modeled off of `Foundation`'s [PropertyListEncoder](https://github.com/apple/swift-corelibs-foundation/blob/main/Sources/Foundation/PropertyListEncoder.swift)
///
/// This custom encoder enables converting custom types into a `Dictionary` representation.
/// All types will be encoded into a `Dictionary`, `Array` or primitive representation unless specified using the `Options` handler.
///
/// - Note: Alternatively one could use a JSON encoder to convert to and from JSON data.
///
/// Example:
///
///       let data = try JSONEncoder().encode(value)
///       let dict = try JSONSerialization.jsonObject(with: data) as? [String : Any]
///
/// However this has two issues.
///   1. We perform unnecessary overhead with encoding and decoding.
///   2. Any `Encodable` type that may be supported by the API is now lost so the serialization must stay in sync with the underlying implementation details of the external library.
///
public final class DictionaryEncoder: TopLevelEncoder {
    public var options: Options
    public var userInfo: [CodingUserInfoKey: Any]

    public init(options: Options = Options(),
                userInfo: [CodingUserInfoKey: Any] = [:])
    {
        self.options = options
        self.userInfo = userInfo
    }

    public func encode<T>(_ value: T) throws -> [String: Any] where T: Encodable {
        let container: Container = try SingleValueContainer(options: options, userInfo: userInfo).encode(value)
        switch container.containerType {
        case .keyed:
            return container.dictionary
        case .singleValue:
            throw DictionaryEncoderError.notKeyedContainer(value)
        case .unkeyed:
            throw DictionaryEncoderError.notKeyedContainer(value)
        }
    }

    /// Options to configure `DictionaryEncoder`.
    open class Options {
        public init() {}

        /// If false the value will be added to the dictionary without encoding.
        open func shouldEncode<T: Encodable>(_: T) -> Bool {
            true
        }
    }
}

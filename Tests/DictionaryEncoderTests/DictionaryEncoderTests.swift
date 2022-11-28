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

@testable import DictionaryEncoder
import XCTest

final class DictionaryEncoderTests: XCTestCase {
    func testDictEncoder_noOptions() throws {
        let encoder = DictionaryEncoder()
        let dictionary: [String: Any] = try encoder.encode(TestEncodable())
        print("\(dictionary)")
        print("\(TestEncodable.asEncodedNoOptions)")
        XCTAssertTrue(dictionary == TestEncodable.asEncodedNoOptions)
    }

    func testDictEncoder() throws {
        let encoder = DictionaryEncoder(options: KeepFoundationOptions())
        let dictionary: [String: Any] = try encoder.encode(TestEncodable())
        print(dictionary)
        print(TestEncodable.asEncoded)
        XCTAssertTrue(dictionary == TestEncodable.asEncoded)
    }

    func testEnumsEncoding() throws {
        let encoder = DictionaryEncoder()
        let dictionary: [String: Any] = try encoder.encode(TestEnums())
        XCTAssertTrue(dictionary == TestEnums.asEncoded)
    }

    func testSuperEncoder() throws {
        let encoder = DictionaryEncoder()
        let dictionary: [String: Any] = try encoder.encode(ChildKeyedEncodable())
        XCTAssertTrue(dictionary == ChildKeyedEncodable.asEncoded)
    }
}

struct TestEncodable: Encodable {
    var stringVar = "string"
    var intVar = 1
    var uintVar: UInt = 2
    var doubleVar: Double = 3
    var floatVar: Float = 4
    var boolVar = true
    var dateVar = Date(timeIntervalSince1970: 1500)
    var urlVar: URL? = URL(string: "tryotter.com")
    var nullVar = NSNull()

    var enums = TestEnums()
    var arrayVar: [TestNestedEncodable] = [TestNestedEncodable(), TestNestedEncodable()]
    var arrayIntVar: [Int] = [1, 2, 3, 4]
    var dictNestedVar: [String: [TestNestedEncodable]] = ["keyNested": [TestNestedEncodable(), TestNestedEncodable()]]
    var dictVar: [String: [String: [Int]]] = ["dictKey0": ["dictKey2": [1, 2, 3, 4]]]

    static var asEncoded: [String: Any] {
        [
            "stringVar": "string",
            "intVar": Int(1),
            "uintVar": UInt(2),
            "doubleVar": Double(3),
            "floatVar": Float(4),
            "boolVar": true,
            "dateVar": Date(timeIntervalSince1970: 1500.0),
            "urlVar": URL(string: "tryotter.com")! as Any,
            "nullVar": NSNull(),
            "enums": TestEnums.asEncoded,
            "arrayVar": [
                TestNestedEncodable.asEncoded,
                TestNestedEncodable.asEncoded,
            ],
            "arrayIntVar": [1, 2, 3, 4],
            "dictNestedVar": [
                "keyNested": [
                    TestNestedEncodable.asEncoded,
                    TestNestedEncodable.asEncoded,
                ],
            ],
            "dictVar": ["dictKey0": ["dictKey2": [1, 2, 3, 4]]],
        ]
    }

    static var asEncodedNoOptions: [String: Any] {
        [
            "stringVar": "string",
            "intVar": Int(1),
            "uintVar": UInt(2),
            "doubleVar": Double(3),
            "floatVar": Float(4),
            "boolVar": true,
            "dateVar": TimeInterval(-978_305_700),
            "urlVar": ["relative": "tryotter.com"],
            "nullVar": NSNull(),
            "enums": TestEnums.asEncoded,
            "arrayVar": [
                TestNestedEncodable.asEncoded,
                TestNestedEncodable.asEncoded,
            ],
            "arrayIntVar": [1, 2, 3, 4],
            "dictNestedVar": [
                "keyNested": [
                    TestNestedEncodable.asEncoded,
                    TestNestedEncodable.asEncoded,
                ],
            ],
            "dictVar": ["dictKey0": ["dictKey2": [1, 2, 3, 4]]],
        ]
    }
}

struct TestEnums: Encodable {
    var keyedEnumEmpty = KeyedEnum.empty
    var keyedEnumWithString = KeyedEnum.withString(stringValue: "test string")
    var unkeyedEnumEmpty = UnkeyedEnum.empty
    var unkeyedEnumWithString = UnkeyedEnum.withString("test string")
    var stringEnum = StringEnum.testStringEnum
    var intEnum = IntEnum.one

    enum KeyedEnum: Encodable {
        case empty
        case withString(stringValue: String)
    }

    enum UnkeyedEnum: Encodable {
        case empty
        case withString(String)
    }

    enum StringEnum: String, Encodable {
        case testStringEnum
    }

    enum IntEnum: Int, Encodable {
        case one = 1
    }

    static var asEncoded: [String: Any] {
        [
            "unkeyedEnumWithString": [
                "withString": [
                    "_0": "test string",
                ],
            ],
            "stringEnum": "testStringEnum",
            "unkeyedEnumEmpty": [
                "empty": [:],
            ],
            "keyedEnumEmpty": [
                "empty": [:],
            ],
            "keyedEnumWithString": [
                "withString": [
                    "stringValue": "test string",
                ],
            ],
            "intEnum": 1,
        ]
    }
}

struct TestNestedEncodable: Encodable {
    var stringVar = "testNested"
    var nested = DoubleNestedEncodable()

    static var asEncoded: [String: Any] {
        [
            "stringVar": "testNested",
            "nested": DoubleNestedEncodable.asEncoded,
        ]
    }

    struct DoubleNestedEncodable: Encodable {
        var stringVar = "testDoubleNested"

        static var asEncoded: [String: Any] {
            [
                "stringVar": "testDoubleNested",
            ]
        }
    }
}

extension NSNull: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class ParentSingleValueEncodable: Encodable {
    var foo = "Foo"

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(foo)
    }
}

class ChildKeyedEncodable: ParentSingleValueEncodable {
    var bar = 1
    var unkeyed = ChildUnkeyedEncodable()

    private enum CodingKeys: String, CodingKey {
        case bar
        case foo
        case unkeyed
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bar, forKey: .bar)
        try container.encode(unkeyed, forKey: .unkeyed)
        // try super.encode(to: encoder) cannot be called because super uses a different container type.
        try super.encode(to: container.superEncoder())
        try super.encode(to: container.superEncoder(forKey: CodingKeys.foo))
    }

    static var asEncoded: [String: Any] {
        [
            "bar": 1,
            "foo": "Foo",
            "super": "Foo",
            "unkeyed": [
                "Bar",
                "Foo",
            ],
        ]
    }
}

class ChildUnkeyedEncodable: ParentSingleValueEncodable {
    var bar = "Bar"

    override func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(bar)
        // try super.encode(to: encoder) cannot be called because super uses a different container type.
        try super.encode(to: container.superEncoder())
    }

    static var asEncoded: [String] {
        [
            "Bar",
            "Foo",
        ]
    }
}

final class KeepFoundationOptions: DictionaryEncoder.Options {
    /// Ensure types that mixpanel will serialize with their own logic do not get encoded into primitives.
    override func shouldEncode<T: Encodable>(_ value: T) -> Bool {
        if let _ = value as? Date {
            return false
        }
        if let _ = value as? URL {
            return false
        }
        if let _ = value as? NSNull {
            return false
        }
        return true
    }
}

extension Dictionary where Value: Any {
    static func == (left: [Key: Value], right: [Key: Value]) -> Bool {
        if left.count != right.count { return false }
        for element in left where !areEqual(right[element.key], element.value) {
            return false
        }
        return true
    }
}

extension Array where Element: Any {
    static func == (left: [Element], right: [Element]) -> Bool {
        if left.count != right.count { return false }
        for (lhs, rhs) in zip(left, right) where !areEqual(lhs, rhs) {
            return false
        }
        return true
    }
}

func areEqual(_ left: Any?, _ right: Any?) -> Bool {
    if type(of: left) == type(of: right),
       String(describing: left) == String(describing: right) { return true }
    if let left = left as? [Any], let right = right as? [Any] { return left == right }
    if let left = left as? [AnyHashable: Any], let right = right as? [AnyHashable: Any] { return left == right }
    return false
}

import XCTest

class RMQParserTest: XCTestCase {

    func testOctet() {
        let parser = RMQParser(data: "\u{2}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(2, parser.parseOctet())

        for _ in 1...1000 {
            XCTAssertEqual(0, parser.parseOctet())
        }
    }

    func testBoolean() {
        let parser = RMQParser(data: "\u{1}\u{0}".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertTrue(parser.parseBoolean())
        XCTAssertFalse(parser.parseBoolean())

        for _ in 1...1000 {
            XCTAssertFalse(parser.parseBoolean())
        }
    }

    func testShortString() {
        let s = "PRECONDITION_FAILED - inequivalent arg 'durable' for queue 'rmqclient.integration-tests.E0B5A093-6B2E-402C-84F3-E93B59DF807B-71865-0003F85C24C90FC6' in vhost '/': received 'false' but current is 'true'"
        let data = NSMutableData()
        var stringLength = s.characters.count
        data.appendBytes(&stringLength, length: 1)
        data.appendData(s.dataUsingEncoding(NSUTF8StringEncoding)!)
        data.appendData("stuffthatshouldn'tbeparsed".dataUsingEncoding(NSUTF8StringEncoding)!)

        let parser = RMQParser(data: data)
        XCTAssertEqual(s, parser.parseShortString())
    }

    func testShortStringWhenAlreadyRead() {
        let parser = RMQParser(data: "\u{4}aaaa".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("aaaa", parser.parseShortString())
        for _ in 1...1000 {
            XCTAssertEqual("", parser.parseShortString())
        }
    }

    func testShortStringWhenNotEnoughDataToReadAfterLongString() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{4}AAAA\u{4}BBB".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("AAAA", parser.parseLongString())
        XCTAssertEqual("", parser.parseShortString())
    }

    func testLongString() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{4}AAAAbbbb".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("AAAA", parser.parseLongString())
    }

    func testLongStringWhenAlreadyRead() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{4}AAAA".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("AAAA", parser.parseLongString())
        for _ in 1...1000 {
            XCTAssertEqual("", parser.parseLongString())
        }
    }

    func testLongStringWhenNotEnoughDataToRead() {
        let parser = RMQParser(data: "\u{0}\u{0}\u{0}\u{4}AAA".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("", parser.parseLongString())
    }

    func testLongStringWhenNotEnoughDataToReadAfterShortString() {
        let parser = RMQParser(data: "\u{4}BBBB\u{0}\u{0}\u{0}\u{4}AAA".dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual("BBBB", parser.parseShortString())
        XCTAssertEqual("", parser.parseLongString())
    }

    func testFieldTableWithAllTypes() {
        let signedByte: Int8 = -128
        let date = NSDate.distantFuture()
        var dict: [String: RMQValue] = [:]
        dict["boolean"] = RMQBoolean(true)
        dict["signed-8-bit"] = RMQSignedByte(signedByte)
        dict["signed-16-bit"] = RMQSignedShort(-129)
        dict["unsigned-16-bit"] = RMQShort(65535)
        dict["signed-32-bit"] = RMQSignedLong(-2147483648)
        dict["unsigned-32-bit"] = RMQLong(4294967295)
        dict["signed-64-bit"] = RMQSignedLonglong(-9223372036854775808)
        dict["32-bit-float"] = RMQFloat(123.5123)
        dict["64-bit-float"] = RMQDouble(9000000.5)
        dict["decimal"] = RMQDecimal()
        dict["long-string"] = RMQLongstr("foo")
        dict["array"] = RMQArray([RMQLongstr("hi"), RMQBoolean(false)])
        dict["timestamp"] = RMQTimestamp(date)
        dict["nested-table"] = RMQTable(["foo": RMQLong(23)])
        dict["void"] = RMQVoid()
        dict["byte-array"] = RMQByteArray("hi".dataUsingEncoding(NSUTF8StringEncoding)!)

        let table = RMQTable(dict)
        let parser = RMQParser(data: table.amqEncoded())
        XCTAssertEqual(dict, parser.parseFieldTable())
    }

}

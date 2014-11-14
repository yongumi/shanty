//
//  Tests.swift
//  Shanty
//
//  Created by Jonathan Wight on 11/13/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

import Cocoa
import XCTest
import Shanty

class Tests: XCTestCase {

    func test_dataScanner1() {

        let input:[UInt16] = [ 11918 ]
        let data = input.withUnsafeBufferPointer() {
            (ptr:UnsafeBufferPointer<UInt16>) -> NSData in
            return NSData(bytes:ptr.baseAddress, length:input.count * sizeof(UInt16))
            }
        let scanner = STYDataScanner(data: data)

        scanner.dataEndianness = .ataScannerDataEndianness_Little;

        XCTAssertEqual(scanner.remainingData(), data)
        
        var int : UInt16 = 0
        let result = scanner.scan_uint16(&int, error: nil)
        
        XCTAssertTrue(result)
        XCTAssertEqual(int, input[0])
        XCTAssertTrue(scanner.remainingData().length == 0)
    }

    func test_dataScanner2() {

        let input:[UInt32] = [ 12345678 ]
        let data = input.withUnsafeBufferPointer() {
            (ptr:UnsafeBufferPointer<UInt32>) -> NSData in
            return NSData(bytes:ptr.baseAddress, length:input.count * sizeof(UInt32))
            }
        let scanner = STYDataScanner(data: data)

        scanner.dataEndianness = .ataScannerDataEndianness_Little;

        XCTAssertEqual(scanner.remainingData(), data)
        
        var int : UInt32 = 0
        let result = scanner.scan_uint32(&int, error: nil)
        
        XCTAssertTrue(result)
        XCTAssertEqual(int, input[0])
        XCTAssertTrue(scanner.remainingData().length == 0)
    }
    
    func test_message() {

//        let message = STYMessage(controlData: [:], metadata: [:], data: nil)
//        let data = message.buffer(nil)

        let bytes = unhex("<004b0002 00000000 7b226372 65617465 64223a31 34313539 32333636 382e3431 33393438 2c225555 4944223a 22433145 38364332 392d4446 37352d34 4546372d 39324633 2d454338 33353145 38444635 30227d7b 7d>")
        let data = bytes.withUnsafeBufferPointer() {
            (ptr:UnsafeBufferPointer<UInt8>) -> NSData in
            return NSData(bytes:ptr.baseAddress, length:bytes.count * sizeof(UInt8))
            }

        let scanner = STYDataScanner(data: data)
        scanner.dataEndianness = .ataScannerDataEndianness_Big;
        var output:STYMessage?
        var error:NSError?
        let result = scanner.scanMessage(&output, error:&error)

        XCTAssertTrue(result)
        XCTAssertNotNil(output)
        XCTAssertNil(error)
    }

}

func unhex(s:String) -> [UInt8] {
    var bytes:[UInt8] = []
    var byte:UInt8 = 0
    var nibbles = 0
    for c in s {
        var nibble:Int?
        switch c {
            case "0":
                nibble = 0
            case "1":
                nibble = 1
            case "2":
                nibble = 2
            case "3":
                nibble = 3
            case "4":
                nibble = 4
            case "5":
                nibble = 5
            case "6":
                nibble = 6
            case "7":
                nibble = 7
            case "8":
                nibble = 8
            case "9":
                nibble = 9
            case "a", "A":
                nibble = 0xA
            case "b", "B":
                nibble = 0xB
            case "c", "C":
                nibble = 0xC
            case "d", "D":
                nibble = 0xD
            case "e", "E":
                nibble = 0xE
            case "f", "F":
                nibble = 0xF
            default:
                continue
        }
        if let nibble = nibble {
            if nibbles == 2 {
                bytes.append(byte)
                nibbles = 0
            }

            if nibbles == 0 {
                byte = UInt8(nibble)
                nibbles = 1
            }
            else if nibbles == 1 {
                byte <<= 4
                byte |= UInt8(nibble)
                nibbles = 2
            }
        }
    }
    if nibbles > 0 {
        bytes.append(byte)
    }
    return bytes
}


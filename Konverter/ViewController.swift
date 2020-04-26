//
//  ViewController.swift
//  Konverter
//
//  Created by ParadiseDuo on 2018/8/21.
//  Copyright © 2018年 ParadiseDuo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var urldecode: NSButton!
    @IBOutlet weak var urlencode: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func decode(_ sender: Any) {
        if let text = self.textView.string.removingPercentEncoding {
            self.textView.string = text
        }
    }
    
    @IBAction func encode(_ sender: Any) {
        if let text = self.textView.string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            self.textView.string = text
        }
    }
    
    @IBAction func sha256(_ sender: Any) {
        self.textView.string = self.textView.string.sha256()
    }
    
    @IBAction func md5(_ sender: Any) {
        self.textView.string = self.textView.string.md5()
    }
    
    
    @IBAction func base64Encode(_ sender: Any) {
        if let s = self.textView.string.base64Encoded() {
            self.textView.string = s
        }
    }
    
    @IBAction func Base64Decode(_ sender: Any) {
        if let s = self.textView.string.base64Decoded() {
            self.textView.string = s
        }
    }
    
    @IBAction func uppercaseString(_ sender: Any) {
        self.textView.string = self.textView.string.uppercased()
    }
    
    @IBAction func lowercaseString(_ sender: Any) {
        self.textView.string = self.textView.string.lowercased()
    }
    
    @IBAction func unicodeDecode(_ sender: NSButton) {
        self.textView.string = self.textView.string.unicodeDecodedString()
    }
    
    @IBAction func unicodeEncode(_ sender: NSButton) {
        self.textView.string = self.textView.string.unicodeEncodedString()
    }
    
    @IBAction func hexEncode(_ sender: NSButton) {
        self.textView.string = self.textView.string.toHexEncodedString()
    }
    
    @IBAction func hexDecode(_ sender: NSButton) {
        if let d = Data(fromHexEncodedString: self.textView.string) {
            self.textView.string = String(data: d, encoding: .utf8) ?? ""
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

extension String {
    
    func unicodeDecodedString()-> String {
        let data = self.data(using: .utf8)
        if let message = String(data: data!, encoding: .nonLossyASCII){
            return message
        }
        return ""
    }
    
    func unicodeEncodedString()-> String {
        let messageData = self.data(using: .nonLossyASCII)
        let text = String(data: messageData!, encoding: .utf8)
        return text ?? ""
    }
    
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func md5() -> String {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        let result = digestData.map { String(format: "%02hhx", $0) }.joined()
        return result
    }
    
    func sha256() -> String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }
}

extension Data {

    // From http://stackoverflow.com/a/40278391:
    init?(fromHexEncodedString string: String) {

        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters
        func decodeNibble(u: UInt16) -> UInt8? {
            switch(u) {
            case 0x30 ... 0x39:
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:
                return UInt8(u - 0x41 + 10)
            case 0x61 ... 0x66:
                return UInt8(u - 0x61 + 10)
            default:
                return nil
            }
        }

        self.init(capacity: string.utf16.count/2)
        var even = true
        var byte: UInt8 = 0
        for c in string.utf16 {
            guard let val = decodeNibble(u: c) else { return nil }
            if even {
                byte = val << 4
            } else {
                byte += val
                self.append(byte)
            }
            even = !even
        }
        guard even else { return nil }
    }
}

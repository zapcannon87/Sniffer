//
//  HTTPConnection.swift
//  Sniffer
//
//  Created by ZapCannon87 on 23/04/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class HTTPConnection: NSObject {
    
    struct readTag {
        
        static let requestHeader: Int   = 1
        static let responseHeader: Int  = 2

        static let requestPayload: Int  = 3
        static let responsePayload: Int = 4

        static let connectIn: Int       = 5
        static let connectOut: Int      = 6
        
    }
    
    struct writeTag {
        
        static let requestHeader: Int   = 1
        static let requestPayload: Int  = 2

        static let responseHeader: Int  = 3
        static let responsePayload: Int = 4

        static let connectHeader: Int   = 5

        static let connectIn: Int       = 6
        static let connectOut: Int      = 7
        
    }
    
    let index: Int
    
    let incomingSocket: GCDAsyncSocket
    
    var outgoingSocket: GCDAsyncSocket!
    
    private(set) weak var server: HTTPProxyServer?
    
    fileprivate var requestHeader: HTTPRequestHeader!
    
    fileprivate var requestHelper: HTTPPayloadHelper = HTTPPayloadHelper.init()
    
    fileprivate var responseHeader: HTTPResponseHeader!
    
    fileprivate var responseHelper: HTTPPayloadHelper = HTTPPayloadHelper.init()
    
    fileprivate var didClose: Bool = false
    
    fileprivate var sessionModel: SessionModel = SessionModel.init()
    
    fileprivate var didAddSessionToManager: Bool = false
    
    init(index: Int, incomingSocket: GCDAsyncSocket, server: HTTPProxyServer) {
        self.index = index
        self.incomingSocket = incomingSocket
        self.server = server
        super.init()
        let queue: DispatchQueue = DispatchQueue(label: "HTTPConnection.delegateQueue")
        self.incomingSocket.synchronouslySetDelegate(
            self,
            delegateQueue: queue
        )
        self.outgoingSocket = GCDAsyncSocket(
            delegate: self,
            delegateQueue: queue
        )
        self.incomingSocket.readData(
            withTimeout: 5,
            tag: readTag.requestHeader
        )
    }
    
    override var hash: Int {
        return self.index
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs: HTTPConnection = object as? HTTPConnection else {
            return false
        }
        let lhs: HTTPConnection = self
        return lhs.index == rhs.index
    }
    
    func close(note: String) {
        guard !self.didClose else {
            return
        }
        self.didClose = true
        
        /* disconnect socket */
        self.incomingSocket.disconnectAfterWriting()
        self.outgoingSocket.disconnectAfterWriting()
        
        /* session */
        if self.didAddSessionToManager {
            self.sessionModel.note = note
            /* session status */
            if note == "EOF" {
                self.sessionModel.status = .finish
            } else {
                self.sessionModel.status = .close
            }
        } else {
            
        }
        
        self.server?.remove(with: self)
    }
    
    func addSessionToManager() {
        guard !self.didAddSessionToManager else {
            return
        }
        self.didAddSessionToManager = true
        SessionManager.shared.append(self.sessionModel)
    }
    
}

extension HTTPConnection: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        
        assert(self.outgoingSocket == sock, "error in sock")
        
        /* session */
        self.sessionModel.remoteIP = host
        self.sessionModel.remotePort = Int(port)
        
        if self.requestHeader.method == HTTPMethod.CONNECT {
            /* https */
            
            let httpVersion: String = self.requestHeader.requestLine?.version ?? "HTTP/1.1"
            let responseData: Data = "\(httpVersion) 200 Connection Established\r\n\r\n".data(using: .ascii)!
            self.incomingSocket.write(
                responseData,
                withTimeout: 5,
                tag: writeTag.connectHeader
            )
            
        } else {
            /* http */
            
            /* session status */
            self.sessionModel.status = .sendRequest
            
            self.outgoingSocket.write(
                self.requestHeader.rawData,
                withTimeout: 5,
                tag: writeTag.requestHeader
            )
            
            /* session */
            self.sessionModel.uploadTraffic += self.requestHeader.rawData.count
            
        }
        
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if sock == self.incomingSocket {
            self.close(note: "Local: \(String(describing: err))")
        } else {
            self.close(note: "Remote: \(String(describing: err))")
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        switch tag {
        case readTag.requestHeader:
            
            assert(sock == self.incomingSocket, "error in sock")
            
            /* get request header */
            guard
                let requestHeader: HTTPRequestHeader = HTTPRequestHeader(data: data),
                let host: String = requestHeader.host
                else
            {
                self.close(note: "error in requestHeader")
                return
            }
            
            /* set request header & request helper */
            self.requestHeader = requestHeader
            self.requestHelper.handleHeader(with: requestHeader)
            
            /* session */
            self.addSessionToManager()
            self.sessionModel.date = Date().timeIntervalSince1970
            self.sessionModel.method = self.requestHeader.method?.rawValue
            self.sessionModel.userAgent = self.requestHeader.userAgent
            self.sessionModel.url = self.requestHeader.url
            self.sessionModel.host = self.requestHeader.host
            self.sessionModel.localIP = self.incomingSocket.localHost
            self.sessionModel.localPort = Int(self.incomingSocket.localPort)
            self.sessionModel.requestHeaders = self.requestHeader.headerString
            
            /* session status */
            self.sessionModel.status = .connect
            
            /* connect remote */
            do {
                try self.outgoingSocket.connect(
                    toHost: host, 
                    onPort: requestHeader.port
                )
            } catch {
                self.close(note: "\(error)")
                return
            }
            
        case readTag.requestPayload:
            
            assert(sock == self.incomingSocket, "error in sock")
            
            self.requestHelper.handlePayload(with: data)
            self.outgoingSocket.write(
                data, 
                withTimeout: 5,
                tag: writeTag.requestPayload
            )
            
            /* session */
            self.sessionModel.uploadTraffic += data.count
            
        case readTag.responseHeader:
            
            assert(sock == self.outgoingSocket, "error in sock")
            
            guard let responseHeader: HTTPResponseHeader = HTTPResponseHeader(data: data) else {
                self.close(note: "error in responseHeader")
                return
            }
            self.responseHeader = responseHeader
            self.responseHelper.handleHeader(with: responseHeader)
            self.incomingSocket.write(
                data,
                withTimeout: 5,
                tag: writeTag.responseHeader
            )
        case readTag.responsePayload:
            assert(sock == self.outgoingSocket, "error in sock")
            self.responseHelper.handlePayload(with: data)
            self.incomingSocket.write(
                data,
                withTimeout: 5,
                tag: writeTag.responsePayload
            )
        case readTag.connectIn:
            assert(sock == self.incomingSocket, "error in sock")
            self.outgoingSocket.write(
                data,
                withTimeout: -1,
                tag: writeTag.connectOut
            )
        case readTag.connectOut:
            assert(sock == self.outgoingSocket, "error in sock")
            self.incomingSocket.write(
                data, 
                withTimeout: -1,
                tag: writeTag.connectIn
            )
        default:
            fatalError()
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        switch tag {
        case writeTag.connectHeader, writeTag.connectIn, writeTag.connectOut:
            if tag != writeTag.connectIn {
                if tag == writeTag.connectHeader {
                    assert(sock == self.incomingSocket, "error in sock")
                    
                    /* session status */
                    self.sessionModel.status = .active
                    
                } else {
                    assert(sock == self.outgoingSocket, "error in sock")
                }
                self.incomingSocket.readData(
                    withTimeout: -1,
                    tag: readTag.connectIn
                )
            }
            if tag != writeTag.connectOut {
                assert(sock == self.incomingSocket, "error in sock")
                self.outgoingSocket.readData(
                    withTimeout: -1,
                    tag: readTag.connectOut
                )
            }
        case writeTag.requestHeader, writeTag.requestPayload:
            assert(sock == self.outgoingSocket, "error in sock")
            if self.requestHelper.isEnd {
                self.outgoingSocket.readData(
                    withTimeout: 5,
                    tag: readTag.responseHeader
                )
            } else {
                self.incomingSocket.readData(
                    withTimeout: 5,
                    tag: readTag.requestPayload
                )
            }
        case writeTag.responseHeader, writeTag.responsePayload:
            assert(sock == self.incomingSocket, "error in sock")
            if self.responseHelper.isEnd {
                self.close(note: "EOF")
            } else {
                self.outgoingSocket.readData(
                    withTimeout: 5,
                    tag: readTag.responsePayload
                )
            }
        default:
            fatalError()
        }
    }
    
}

// MARK: - Model

enum HTTPMethod: String {
    case OPTIONS = "OPTIONS"
    case GET     = "GET"
    case HEAD    = "HEAD"
    case POST    = "POST"
    case PUT     = "PUT"
    case DELETE  = "DELETE"
    case TRACE   = "TRACE"
    case CONNECT = "CONNECT"
}

class HTTPHeader {
    
    static let CRLF2Data: Data = "\r\n\r\n".data(using: .ascii)!
    
    static let ChunkedTransferEncodingEndData: Data = "0\r\n\r\n".data(using: .ascii)!
    
    let rawData: Data
    
    let headerString: String
    
    let headers: [String]
    
    let headersLength: Int
    
    let lengthOfPayloadInHeaderPacket: Int
    
    init?(data: Data) {
        self.rawData = data
        var headerData: Data
        if let CRLF2Range1: Range<Data.Index> = data.range(
            of: HTTPHeader.CRLF2Data,
            options: .backwards,
            in: data.startIndex..<data.endIndex
            )
        {
            let subData: Data = data.subdata(
                in: data.startIndex..<CRLF2Range1.lowerBound
            )
            if let CRLF2Range2: Range<Data.Index> = subData.range(
                of: HTTPHeader.CRLF2Data,
                options: .backwards,
                in: subData.startIndex..<subData.endIndex
                )
            {
                headerData = subData.subdata(
                    in: subData.startIndex..<CRLF2Range2.lowerBound
                )
            } else {
                headerData = subData
            }
            let headersLength: Int = headerData.count + HTTPHeader.CRLF2Data.count
            self.headersLength = headersLength
            self.lengthOfPayloadInHeaderPacket = data.count - headersLength
        } else {
            headerData = data
            self.headersLength = headerData.count
            self.lengthOfPayloadInHeaderPacket = 0
        }
        guard let headerString: String = String(data: headerData, encoding: .ascii) else {
            return nil
        }
        self.headerString = headerString
        let headers: [String] = headerString.components(
            separatedBy: "\r\n"
        )
        guard headers.count >= 2 else {
            return nil
        }
        self.headers = headers
    }
    
    lazy var connectionKeepAlive: Bool? = {
        for item in self.headers {
            if item.hasPrefix("Connection:")
                || item.hasPrefix("Proxy-Connection:")
            {
                if item.contains("keep-alive") {
                    return true
                } else if item.contains("close") {
                    return false
                }
            }
        }
        return nil
    }()
    
    lazy var chunkedTransferEncoding: Bool = {
        if let value: String = self.getHeaderValue(with: "Transfer-Encoding:"),
            value.contains("chunked")
        {
            return true
        } else {
            return false
        }
    }()
    
    lazy var contentLength: Int? = {
        if let value: String = self.getHeaderValue(with: "Content-Length:"),
            let length: Int = Int(value)
        {
            return length
        } else {
            return nil
        }
    }()
    
    lazy var contentType: String? = {
        return self.getHeaderValue(with: "Content-Type:")
    }()
    
    func getHeaderValue(with key: String) -> String? {
        for item in self.headers {
            if item.hasPrefix(key) {
                let value: String = item.replacingOccurrences(
                    of: key,
                    with: "",
                    options: [.anchored, .caseInsensitive],
                    range: item.startIndex..<item.endIndex
                )
                return value.trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines
                )
            }
        }
        return nil
    }
    
}

class HTTPRequestHeader: HTTPHeader {
    
    lazy var requestLine: (method: String, url: String, version: String?)? = {
        guard
            let comps: [String] = self.headers
                .first?
                .trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines
                ).components(separatedBy: " "),
            comps.count >= 2
            else
        {
            return nil
        }
        if comps.count >= 3 {
            return (comps[0], comps[1], comps[2])
        } else {
            return (comps[0], comps[1], nil)
        }
    }()
    
    lazy var method: HTTPMethod? = {
        guard
            let value: String = self.requestLine?.method,
            let method = HTTPMethod(rawValue: value)
            else
        {
            return nil
        }
        return method
    }()
    
    lazy var url: String? = {
        guard let requestLineUrl: String = self.requestLine?.url else {
            return nil
        }
        if requestLineUrl.hasPrefix("http") {
            return requestLineUrl
        } else {
            if let method: HTTPMethod = self.method,
                method == .CONNECT
            {
                return "https://\(requestLineUrl)"
            } else {
                return "http://\(requestLineUrl)"
            }
        }
    }()
    
    lazy var host: String? = {
        return self.getHeaderValue(with: "Host:")
    }()
    
    lazy var port: UInt16 = {
        if let urlString: String = self.url,
            let port: Int = URLComponents(string: urlString)?.port
        {
            return UInt16(port)
        } else {
            return 80
        }
    }()
    
    lazy var userAgent: String? = {
        return self.getHeaderValue(with: "User-Agent:")
    }()
    
}

class HTTPResponseHeader: HTTPHeader {
    
    lazy var responseLine: (httpVersion: String, statusCode: String)? = {
        guard
            let comps: [String] = self.headers
                .first?
                .components(separatedBy: " "),
            comps.count >= 2
            else
        {
            return nil
        }
        return (comps[0], comps[1])
    }()
    
    var httpVersion: String? {
        return self.responseLine?.httpVersion
    }
    
    var statusCode: String? {
        return self.responseLine?.statusCode
    }
    
}

class HTTPPayloadHelper {
    
    private(set) var isChunked: Bool?
    
    private(set) var isEnd: Bool = false
    
    private var remainLength: Int = -1
    
    func handleHeader(with header: HTTPHeader) {
        if let contentLength: Int = header.contentLength {
            self.isChunked = false
            self.remainLength = contentLength - header.lengthOfPayloadInHeaderPacket
            self.isEnd = (self.remainLength <= 0)
        } else if header.chunkedTransferEncoding {
            self.isChunked = true
            self.isEnd = (self.checkIfChunkedTransferEnd(with: header.rawData))
        } else {
            self.isChunked = nil
            self.isEnd = true
        }
    }
    
    func handlePayload(with data: Data) {
        if let _isChunked: Bool = self.isChunked {
            if _isChunked {
                self.isEnd = (self.checkIfChunkedTransferEnd(with: data))
            } else {
                self.remainLength -= data.count
                self.isEnd = (self.remainLength <= 0)
            }
        } else {
            // unnecessary
            self.isEnd = true
        }
    }
    
    private func checkIfChunkedTransferEnd(with data: Data) -> Bool {
        if
            let _: Range<Data.Index> = data.range(
                of: HTTPHeader.ChunkedTransferEncodingEndData,
                options: [.anchored, .backwards],
                in: data.startIndex..<data.endIndex
            )
        {
            return true
        } else {
            return false
        }
    }
    
}

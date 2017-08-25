//
//  TCPConnection.swift
//  Sniffer
//
//  Created by ZapCannon87 on 02/05/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import ZPTCPIPStack
import CocoaAsyncSocket

class TCPConnection: NSObject {
    
    let index: Int
    
    let local: ZPTCPConnection
    
    let remote: GCDAsyncSocket
    
    private(set) weak var server: TCPProxyServer?
    
    fileprivate var localFin: Bool = false
    
    fileprivate var remoteFin: Bool = false
    
    fileprivate var didClose: Bool = false
    
    init(index: Int, localSocket: ZPTCPConnection, server: TCPProxyServer) {
        self.index = index
        self.local = localSocket
        self.remote = GCDAsyncSocket()
        self.server = server
        super.init()
        let queue: DispatchQueue = DispatchQueue(label: "TCPConnection.delegateQueue")
        self.local.asyncSetDelegate(
            self,
            delegateQueue: queue
        )
        self.remote.synchronouslySetDelegate(
            self,
            delegateQueue: queue
        )
        do {
            try self.remote.connect(
                toHost: self.local.destAddr, 
                onPort: self.local.destPort
            )
        } catch {
            self.close(with: "\(error)")
        }
    }
    
    override var hash: Int {
        return self.index
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs: TCPConnection = object as? TCPConnection else {
            return false
        }
        let lhs: TCPConnection = self
        return lhs.index == rhs.index
    }
    
    func close(with note: String) {
        guard !self.didClose else {
            return
        }
        self.didClose = true
        
        self.local.closeAfterWriting()
        self.remote.disconnectAfterWriting()
        
        self.server?.remove(connection: self)
    }
    
}

extension TCPConnection: ZPTCPConnectionDelegate {
    
    func connection(_ connection: ZPTCPConnection, didRead data: Data) {
        self.remote.write(
            data,
            withTimeout: 5,
            tag: data.count
        )
    }
    
    func connection(_ connection: ZPTCPConnection, didWriteData length: UInt16) {
        self.remote.readData(
            withTimeout: -1,
            buffer: nil,
            bufferOffset: 0,
            maxLength: UInt(UINT16_MAX / 2),
            tag: 0
        )
    }
    
    func connectionDidCloseReadStream(_ connection: ZPTCPConnection) {
        self.localFin = true
        if self.localFin && self.remoteFin {
            self.close(with: "EOF")
        }
    }
    
    func connection(_ connection: ZPTCPConnection, didDisconnectWithError err: Error) {
        self.close(with: "Local: \(err)")
    }
    
}

extension TCPConnection: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        self.local.readData()
        self.remote.readData(
            withTimeout: -1,
            buffer: nil,
            bufferOffset: 0,
            maxLength: UInt(UINT16_MAX / 2),
            tag: 0
        )
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        self.local.write(data)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        self.local.readData()
    }
    
    func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        self.remoteFin = true
        if self.localFin && self.remoteFin {
            self.close(with: "EOF")
        }
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        self.close(with: "Remote: \(String(describing: err))")
    }
    
}

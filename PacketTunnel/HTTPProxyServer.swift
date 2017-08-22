//
//  HTTPProxyServer.swift
//  Sniffer
//
//  Created by ZapCannon87 on 23/04/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class HTTPProxyServer: NSObject {
    
    let listenSocket: GCDAsyncSocket
    
    fileprivate var index: Int = 0
    
    override init() {
        self.listenSocket = GCDAsyncSocket()
        super.init()
        self.listenSocket.synchronouslySetDelegate(
            self,
            delegateQueue: DispatchQueue(label: "HTTPProxyServer.listenSocket.delegateQueue")
        )
    }
    
    func start(with host: String) {
        do {
            try self.listenSocket.accept(onInterface: host, port: 0)
        } catch {
            assert(false, "\(error)")
        }
    }
    
    func stop() {
        self.listenSocket.disconnect()
    }
    
    func remove() {
        self.listenSocket.delegateQueue?.async {
            
        }
    }
    
}

extension HTTPProxyServer: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
    }
    
}

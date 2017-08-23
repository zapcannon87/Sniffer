//
//  TCPProxyServer.swift
//  Sniffer
//
//  Created by ZapCannon87 on 02/05/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import NetworkExtension
import ZPTCPIPStack

class TCPProxyServer: NSObject {
    
    let client: NEPacketTunnelFlow
    
    let server: ZPPacketTunnel
    
    fileprivate var index: Int = 0
    
    fileprivate var connections: Set<TCPConnection> = []
    
    init?(tunnelFlow: NEPacketTunnelFlow) {
        self.client = tunnelFlow
        self.server = ZPPacketTunnel.shared()
        super.init()
        self.server.delegate(
            self,
            delegateQueue: DispatchQueue(label: "TCPProxyServer.server.delegateQueue")
        )
    }
    
    func remove(connection: TCPConnection) {
        self.server.delegateQueue.async {
            self.connections.remove(connection)
        }
    }
    
}

extension TCPProxyServer: ZPPacketTunnelDelegate {
    
    func tunnel(_ tunnel: ZPPacketTunnel, didEstablishNewTCPConnection conn: ZPTCPConnection) {
        let tcpConn: TCPConnection = TCPConnection(
            index: self.index,
            localSocket: conn,
            server: self
        )
        self.index += 1
        self.connections.insert(tcpConn)
    }
    
}

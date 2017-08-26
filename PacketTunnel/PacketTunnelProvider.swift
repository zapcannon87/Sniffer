//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by ZapCannon87 on 13/04/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import NetworkExtension

var Tunnel: PacketTunnelProvider?

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    var httpProxy: HTTPProxyServer?
    
    var tcpProxy: TCPProxyServer?

    override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        Tunnel = self
        /* http */
        self.httpProxy = HTTPProxyServer()
        self.httpProxy!.start(with: "localhost")
        /* settings */
        let tunnelSettings: NEPacketTunnelNetworkSettings = self.newPacketTunnelSettings(
            proxyHost: self.httpProxy!.listenSocket.localHost!,
            proxyPort: self.httpProxy!.listenSocket.localPort
        )
        /* tcp */
        self.tcpProxy = TCPProxyServer()
        self.tcpProxy!.server.ipv4Setting(
            withAddress: tunnelSettings.iPv4Settings!.addresses[0],
            netmask: tunnelSettings.iPv4Settings!.subnetMasks[0]
        )
        self.tcpProxy!.server.mtu(tunnelSettings.mtu!.uint16Value) { datas, numbers in
            guard
                let _datas: [Data] = datas,
                let _nums: [NSNumber] = numbers
                else
            {
                return
            }
            self.packetFlow.writePackets(_datas, withProtocols: _nums)
        }
        /* start */
        self.setTunnelNetworkSettings(tunnelSettings) { err in
            completionHandler(err)
            if err == nil {
                self.packetFlow.readPackets() { datas, nums in
                    self.handlePackets(packets: datas, protocols: nums)
                }
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        
    }
    
    func handlePackets(packets: [Data], protocols: [NSNumber]) {
        for (index, data) in packets.enumerated() {
            switch protocols[index].int32Value {
            case AF_INET:
                self.tcpProxy?.server.ipPacketInput(data)
            case AF_INET6:
                break
            default:
                fatalError()
            }
        }
        self.packetFlow.readPackets { datas, numbers in
            self.handlePackets(packets: datas, protocols: numbers)
        }
    }
    
    func newPacketTunnelSettings(proxyHost: String, proxyPort: UInt16) -> NEPacketTunnelNetworkSettings {
        let settings: NEPacketTunnelNetworkSettings = NEPacketTunnelNetworkSettings(
            tunnelRemoteAddress: "240.0.0.1"
        )
        
        /* proxy settings */
        let proxySettings: NEProxySettings = NEProxySettings()
        proxySettings.httpServer = NEProxyServer(
            address: proxyHost,
            port: Int(proxyPort)
        )
        proxySettings.httpsServer = NEProxyServer(
            address: proxyHost,
            port: Int(proxyPort)
        )
        proxySettings.autoProxyConfigurationEnabled = false
        proxySettings.httpEnabled = true
        proxySettings.httpsEnabled = true
        proxySettings.excludeSimpleHostnames = true
        proxySettings.exceptionList = [
            "192.168.0.0/16",
            "10.0.0.0/8",
            "172.16.0.0/12",
            "127.0.0.1",
            "localhost",
            "*.local"
        ]
        settings.proxySettings = proxySettings
        
        /* ipv4 settings */
        let ipv4Settings: NEIPv4Settings = NEIPv4Settings(
            addresses: [settings.tunnelRemoteAddress],
            subnetMasks: ["255.255.255.255"]
        )
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        ipv4Settings.excludedRoutes = [
            NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0")
        ]
        settings.iPv4Settings = ipv4Settings
        
        /* MTU */
        settings.mtu = NSNumber(value: UINT16_MAX)
        
        return settings
    }
    
}

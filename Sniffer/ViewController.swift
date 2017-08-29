//
//  ViewController.swift
//  Sniffer
//
//  Created by ZapCannon87 on 22/08/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {

    @IBOutlet weak var oneSwitch: UISwitch!
    
    @IBAction func toggle(_ sender: UISwitch) {
        guard let pm: NETunnelProviderManager = self.manager else {
            return
        }
        if pm.connection.status == .connected {
            (pm.connection as? NETunnelProviderSession)?.stopTunnel()
        } else {
            do {
                try (pm.connection as? NETunnelProviderSession)?.startTunnel(options: nil)
            } catch {
                assertionFailure("\(error)")
            }
        }
    }
    
    var manager: NETunnelProviderManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            guard let pm: NETunnelProviderManager = managers?.first else {
                let pm = NETunnelProviderManager()
                let pt = NETunnelProviderProtocol()
                #if TEST
                    pt.providerBundleIdentifier = "zapcannon87.TestSZ.PacketTunnel"
                    pt.serverAddress = "TestSZ"
                #else
                    pt.providerBundleIdentifier = "zapcannon87.Sniffer.PacketTunnel"
                    pt.serverAddress = "Sniffer"
                #endif
                pm.protocolConfiguration = pt
                pm.isEnabled = true
                pm.saveToPreferences() { err in
                    if let err: Error = err {
                        assertionFailure("\(err)")
                    }
                }
                return
            }
            pm.isEnabled = true
            pm.saveToPreferences() { err in
                if let err: Error = err {
                    assertionFailure("\(err)")
                }
                self.oneSwitch.isOn = (pm.connection.status == .connected)
                self.manager = pm
            }
        }
    }
    
}


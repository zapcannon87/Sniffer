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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func toggle(_ sender: UISwitch) {
        guard let tpm: NETunnelProviderManager = TunnelManager.tpm else {
            UIAlertController.showErrorAlert(
                target: self,
                message: "Check your VPN configurations."
            )
            sender.setOn(false, animated: false)
            return
        }
        if !tpm.isEnabled {
            UIAlertController.showActionAlert(
                target: self,
                message: "Enable VPN manager ?"
            ) {
                self.viewActive(enable: false)
                TunnelManager.enable(manager: tpm) {
                    self.viewActive(enable: true)
                }
            }
            sender.setOn(false, animated: false)
        } else {
            let session: NETunnelProviderSession = tpm.session
            if session.status == .connected {
                session.stopTunnel()
            } else if session.status == .disconnected {
                do {
                    try session.startTunnel(options: nil)
                } catch {
                    assertionFailure("\(error)")
                }
            } else {
                print(session.status)
            }
        }
    }
    
    lazy var oneSwitch: UISwitch = {
        return (self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! SwitchCell).oneSwitch
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.vpnStatusDidChange),
            name: .NEVPNStatusDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.vpnConfigurationChange),
            name: .NEVPNConfigurationChange,
            object: nil
        )
        
        self.viewActive(enable: false)
        TunnelManager.shared.loadAllFromPreferences() {
            self.viewActive(enable: true)
            NotificationCenter.default.post(
                name: .NEVPNStatusDidChange,
                object: nil
            )
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func viewActive(enable: Bool) {
        self.view.isUserInteractionEnabled = enable
        if enable {
            self.activityIndicator.stopAnimating()
        } else {
            self.activityIndicator.startAnimating()
        }
    }
    
    func vpnStatusDidChange() {
        guard let tpm = TunnelManager.tpm else {
            return
        }
        let status: NEVPNStatus = tpm.session.status
        self.oneSwitch.setOn(
            (status == .connected || status == .connecting),
            animated: false
        )
    }
    
    func vpnConfigurationChange() {
        guard let tpm = TunnelManager.tpm else {
            return
        }
        self.viewActive(enable: false)
        tpm.loadFromPreferences() { loadErr in
            self.viewActive(enable: true)
            if let err: Error = loadErr {
                print(err)
            }
        }
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            return tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as! SwitchCell
        default:
            fatalError()
        }
    }
    
}

class SwitchCell: UITableViewCell {
    
    @IBOutlet weak var oneSwitch: UISwitch!
    
}


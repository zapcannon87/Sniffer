//
//  Extension.swift
//  Sniffer
//
//  Created by ZapCannon87 on 31/08/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import UIKit
import NetworkExtension

extension NETunnelProviderManager {
    
    var session: NETunnelProviderSession {
        return self.connection as! NETunnelProviderSession
    }
    
}

extension UIAlertController {
    
    static func showErrorAlert(target: UIViewController, message: String) {
        let alert: UIAlertController = UIAlertController(
            title: "Error", 
            message: message,
            preferredStyle: .alert
        )
        let ok: UIAlertAction = UIAlertAction(
            title: "OK",
            style: .cancel
        )
        alert.addAction(ok)
        target.present(alert, animated: true, completion: nil)
    }
    
    static func showActionAlert(target: UIViewController, message: String, action: @escaping () -> Void) {
        let alert: UIAlertController = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        let cancel: UIAlertAction = UIAlertAction(
            title: "Cancel",
            style: .cancel
        )
        let ok: UIAlertAction = UIAlertAction(
            title: "OK",
            style: .default
        ) { _ in
            action()
        }
        alert.addAction(cancel)
        alert.addAction(ok)
        target.present(alert, animated: true, completion: nil)
    }
    
}

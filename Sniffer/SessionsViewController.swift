//
//  SessionsViewController.swift
//  Sniffer
//
//  Created by ZapCannon87 on 03/09/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import UIKit
import NetworkExtension

class SessionsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var activeModels: [SessionModel] = []
    
    var closedModels: [SessionModel] = []
    
    let dateFormatter: DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Sessions"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(self.refresh)
        )
        
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        
        self.refresh()
    }
    
    func refresh() {
        guard let tpm: NETunnelProviderManager = TunnelManager.tpm else {
            UIAlertController.showErrorAlert(
                target: self,
                message: "Check your VPN configurations."
            )
            return
        }
        let session: NETunnelProviderSession = tpm.session
        guard session.status == .connected else {
            UIAlertController.showErrorAlert(
                target: self,
                message: "VPN should be connected"
            )
            return
        }
        self.viewActive(enable: false)
        let message: Data = "getSessionsData".data(using: .ascii)!
        do {
            try session.sendProviderMessage(message) { data in
                self.viewActive(enable: true)
                guard let _data: Data = data else {
                    return
                }
                do {
                    let jsonObj: Any = try JSONSerialization.jsonObject(with: _data, options: [.allowFragments])
                    guard let json: [String : Any] = jsonObj as? [String : Any],
                        let activeDics: [[String : Any]] = json.value(for: "activeSessions"),
                        let closedDics: [[String : Any]] = json.value(for: "closedSessions") else {
                        assertionFailure("\(jsonObj)")
                        return
                    }
                    
                    /* active */
                    var activeModels: [SessionModel] = [SessionModel].init(
                        repeating: SessionModel(),
                        count: activeDics.count
                    )
                    for (index, item) in activeDics.enumerated() {
                        activeModels[index] = SessionModel(dic: item)
                    }
                    self.activeModels = activeModels
                    
                    /* closed */
                    var closedModels: [SessionModel] = [SessionModel].init(
                        repeating: SessionModel(),
                        count: closedDics.count
                    )
                    for (index, item) in closedDics.enumerated() {
                        closedModels[index] = SessionModel(dic: item)
                    }
                    self.closedModels = closedModels
                    
                    self.tableView.reloadData()
                } catch {
                    assertionFailure("\(error)")
                }
            }
        } catch {
            assertionFailure("\(error)")
        }
    }
    
    func viewActive(enable: Bool) {
        self.view.isUserInteractionEnabled = enable
        self.navigationItem.rightBarButtonItem?.isEnabled = enable
        if enable {
            self.activityIndicator.stopAnimating()
        } else {
            self.activityIndicator.startAnimating()
        }
    }
    
}

extension SessionsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Active Sessions"
        } else {
            return "Closed Sessions"
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.activeModels.count
        } else {
            return self.closedModels.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SessionsViewCell = tableView.dequeueReusableCell(withIdentifier: "SessionsViewCell") as! SessionsViewCell
        var model: SessionModel
        if indexPath.section == 0 {
            model = self.activeModels[self.activeModels.count - indexPath.row - 1]
        } else {
            model = self.closedModels[self.closedModels.count - indexPath.row - 1]
        }
        cell.indexLabel.text = "\(model.index)"
        cell.methodLabel.text = model.method
        if let timeInterval: Double = model.date {
            cell.dateLabel.text = self.dateFormatter.string(
                from: Date(timeIntervalSince1970: timeInterval)
            )
        } else {
            cell.dateLabel.text = ""
        }
        cell.urlLabel.text = model.url
        var misc: String = model.status.rawValue
        if let userAgent: String = model.userAgent {
            misc += " - \(userAgent)"
        }
        cell.miscLabel.text = misc
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let vc: SessionViewController = self.storyboard?.instantiateViewController(withIdentifier: "SessionViewController") as! SessionViewController
        var model: SessionModel
        if indexPath.section == 0 {
            model = self.activeModels[self.activeModels.count - indexPath.row - 1]
        } else {
            model = self.closedModels[self.closedModels.count - indexPath.row - 1]
        }
        vc.model = model
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

// MARK: - View

class SessionsViewCell: UITableViewCell {
    
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var methodLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var miscLabel: UILabel!
    
}

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
    
    var models: [SessionModel] = []
    
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
        
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
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
                    guard let jsonDics: [[String : Any]] = jsonObj as? [[String : Any]] else {
                        assertionFailure("\(jsonObj)")
                        return
                    }
                    var models: [SessionModel] = [SessionModel].init(
                        repeating: SessionModel(),
                        count: jsonDics.count
                    )
                    for (index, item) in jsonDics.enumerated() {
                        models[index] = SessionModel(dic: item)
                    }
                    self.models = models
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SessionsViewCell = tableView.dequeueReusableCell(withIdentifier: "SessionsViewCell") as! SessionsViewCell
        let model: SessionModel = self.models[indexPath.row]
        cell.indexLabel.text = "\(model.index ?? -1)"
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
    
}

// MARK: - View

class SessionsViewCell: UITableViewCell {
    
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var methodLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var miscLabel: UILabel!
    
}

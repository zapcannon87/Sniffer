//
//  SessionViewController.swift
//  Sniffer
//
//  Created by ZapCannon87 on 04/09/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import UIKit

class SessionViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var model: SessionModel!
    
    let dateFormatter: DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "\(self.model.index ?? -1)"
        
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
    }
    
}

extension SessionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 16
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SessionViewCell = tableView.dequeueReusableCell(withIdentifier: "SessionViewCell") as! SessionViewCell
        switch indexPath.row {
        case 0:
            cell.headerLabel.text = "Date"
            if let timeInterval: Double = self.model.date {
                cell.textView.text = self.dateFormatter.string(
                    from: Date(timeIntervalSince1970: timeInterval)
                )
            } else {
                cell.textView.text = ""
            }
        case 1:
            cell.headerLabel.text = "Method"
            cell.textView.text = self.model.method ?? ""
        case 2:
            cell.headerLabel.text = "User Agent"
            cell.textView.text = self.model.userAgent ?? ""
        case 3:
            cell.headerLabel.text = "Host"
            cell.textView.text = self.model.host ?? ""
        case 4:
            cell.headerLabel.text = "URL"
            cell.textView.text = self.model.url ?? ""
        case 5:
            cell.headerLabel.text = "Local IP"
            cell.textView.text = self.model.localIP ?? ""
        case 6:
            cell.headerLabel.text = "Local Port"
            cell.textView.text = "\(self.model.localPort ?? -1)"
        case 7:
            cell.headerLabel.text = "Remote IP"
            cell.textView.text = self.model.remoteIP ?? ""
        case 8:
            cell.headerLabel.text = "Remote Port"
            cell.textView.text = "\(self.model.remotePort ?? -1)"
        case 9:
            cell.headerLabel.text = "Upload Traffic"
            cell.textView.text = ByteCountFormatter.string(
                fromByteCount: Int64(self.model.uploadTraffic),
                countStyle: .decimal
            )
        case 10:
            cell.headerLabel.text = "Download Traffic"
            cell.textView.text = ByteCountFormatter.string(
                fromByteCount: Int64(self.model.downloadTraffic),
                countStyle: .decimal
            )
        case 11:
            cell.headerLabel.text = "Status"
            cell.textView.text = self.model.status.rawValue
        case 12:
            cell.headerLabel.text = "Timing"
            if let timings: [String : [String : Double]] = self.model.timings {
                var texts: [String] = []
                if let establishing: Double = self.model.getTiming(type: .establishing, dic: timings) {
                    if establishing > 0 {
                        texts.append("Establishing: \(establishing)")
                    } else {
                        texts.append("Establishing: Not Finish")
                    }
                }
                if let requestSending: Double = self.model.getTiming(type: .requestSending, dic: timings) {
                    if requestSending > 0 {
                        texts.append("Request Sending: \(requestSending)")
                    } else {
                        texts.append("Request Sending: Not Finish")
                    }
                }
                if let responseReceiving: Double = self.model.getTiming(type: .responseReceiving, dic: timings) {
                    if responseReceiving > 0 {
                        texts.append("Response Receiving: \(responseReceiving)")
                    } else {
                        texts.append("Response Receiving: Not Finish")
                    }
                }
                if let transmitting: Double = self.model.getTiming(type: .transmitting, dic: timings) {
                    if transmitting > 0 {
                        texts.append("Transmitting: \(transmitting)")
                    } else {
                        texts.append("Transmitting: Not Finish")
                    }
                }
                cell.textView.text = texts.joined(separator: "\n")
            } else {
                cell.textView.text = ""
            }
        case 13:
            cell.headerLabel.text = "Note"
            cell.textView.text = self.model.note ?? ""
        case 14:
            cell.headerLabel.text = "Request Headers"
            cell.textView.text = self.model.requestHeaders ?? ""
        case 15:
            cell.headerLabel.text = "Response Headers"
            cell.textView.text = self.model.responseHeaders ?? ""
        default:
            fatalError()
        }
        return cell
    }
    
}

class SessionViewCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var textView: UILabel!
    
}

//
//  SessionManager.swift
//  Sniffer
//
//  Created by ZapCannon87 on 01/09/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation

class SessionManager {
    
    private(set) var sessions: [SessionModel] = []
    
    static let shared: SessionManager = SessionManager()
    
    private let queue: DispatchQueue = DispatchQueue(label: "SessionManager.queue")
    
    private var index: Int = 0
    
    private init() {}
    
    func append(_ session: SessionModel) {
        self.queue.async {
            session.index = self.index
            self.index += 1
            if self.sessions.count == 100 {
                let _ = self.sessions.dropFirst()
            }
            self.sessions.append(session)
        }
    }
    
    func getSessionsData(completionHandler: @escaping (Data) -> Void) {
        self.queue.async {
            var dics: [[String : Any]] = Array<[String : Any]>.init(
                repeating: [:],
                count: self.sessions.count
            )
            for (index, item) in self.sessions.enumerated() {
                dics[index] = item.dic
            }
            do {
                let data: Data = try JSONSerialization.data(
                    withJSONObject: dics,
                    options: []
                )
                completionHandler(data)
            } catch {
                assertionFailure("\(error)")
            }
        }
    }
    
}

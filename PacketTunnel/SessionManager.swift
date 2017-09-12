//
//  SessionManager.swift
//  Sniffer
//
//  Created by ZapCannon87 on 01/09/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation

class SessionManager {
    
    static let shared: SessionManager = SessionManager()
    
    private(set) var activeSessions: Set<SessionModel> = []
    
    private(set) var closedSessions: Array<SessionModel> = []
    
    private let queue: DispatchQueue = DispatchQueue(label: "SessionManager.queue")
    
    private var index: Int = 0
    
    private init() {}
    
    func closedAppend(_ session: SessionModel) {
        self.queue.async {
            self.activeSessions.remove(session)
            if self.closedSessions.count == 50 {
                let _ = self.closedSessions.remove(at: 0)
            }
            self.closedSessions.append(session)
        }
    }
    
    func activeAppend(_ session: SessionModel) {
        self.queue.async {
            /* maybe unnecessary, prevent overflow. :P */
            if self.index == Int.max {
                /*
                 unsafe if still has a index == 0 in set!
                 oh, shit. I don't want to consider it anymore.
                 */
                self.index = 0
            }
            session.index = self.index
            self.index += 1
            self.activeSessions.insert(session)
        }
    }
    
    func getSessionsData(completionHandler: @escaping (Data) -> Void) {
        self.queue.async {
            /* active */
            var activeDics: [[String : Any]] = Array<[String : Any]>.init(
                repeating: [:],
                count: self.activeSessions.count
            )
            for (index, item) in self.activeSessions.enumerated() {
                activeDics[index] = item.getDic()
            }
            /* closed */
            var closedDics: [[String : Any]] = Array<[String : Any]>.init(
                repeating: [:],
                count: self.closedSessions.count
            )
            for (index, item) in self.closedSessions.enumerated() {
                closedDics[index] = item.getDic()
            }
            do {
                let json: [String : Any] = [
                    "activeSessions" : activeDics,
                    "closedSessions" : closedDics
                ]
                let data: Data = try JSONSerialization.data(
                    withJSONObject: json,
                    options: []
                )
                completionHandler(data)
            } catch {
                assertionFailure("\(error)")
            }
        }
    }
    
}

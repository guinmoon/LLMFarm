//
//  Message.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/20/23.
//

import Foundation

struct Message: Identifiable {
    enum State: Equatable {
        case none
        case error
        case typed
        case predicting
        case predicted(totalSecond: Double)
    }

    enum Sender {
        case user
        case system
    }

    var id = UUID()
    var sender: Sender
    var state: State = .none
    var text: String
    var tok_sec: Double
    var header: String = ""
    var attachment: String? = nil
    var attachment_type: String? = nil
}

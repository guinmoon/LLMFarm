//
//  StringExt.swift
//  Mia
//
//  Created by Byron Everson on 12/25/22.
//

import Foundation

extension String {
    
    // Convenience
    func binURL(_ dir: URL) -> URL {
        dir.appendingPathComponent(self).appendingPathExtension("bin")
    }
    
    // Used with a filename to produce a url for saving to
    func localModelSaveURL() -> URL {
        let supportDir = try! FileManager.default.url(for: .applicationSupportDirectory, in: .allDomainsMask, appropriateFor: nil, create: true)
        return supportDir.appendingPathComponent(self)
    }
    
}

extension String: Error {
}

//
//  Orientation_helper.swift
//  LLMFarm
//
//  Created by guinmoon on 03.07.2023.
//

import Foundation
import SwiftUI


class SGConvenience{
    #if os(watchOS)
    static var deviceWidth:CGFloat = WKInterfaceDevice.current().screenBounds.size.width
    #elseif os(iOS)
    static var deviceWidth:CGFloat = UIScreen.main.bounds.size.width
    #elseif os(macOS)
    static var deviceWidth:CGFloat? = NSScreen.main?.visibleFrame.size.width // You could implement this to force a CGFloat and get the full device screen size width regardless of the window size with .frame.size.width
    #endif
}

#if os(iOS) || os(watchOS) || os(tvOS)

extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}


final class OrientationInfo: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }
    
    enum UserInterfaceIdiom {
        case phone
        case not_phone
    }
    
    @Published var orientation: Orientation
    @Published var userInterfaceIdiom: UserInterfaceIdiom
    
    private var _observer: NSObjectProtocol?
    
    init() {
        // fairly arbitrary starting value for 'flat' orientations
        if UIDevice.current.orientation.isLandscape {
            self.orientation = .landscape
        }
        else {
            self.orientation = .portrait
        }
        if  UIDevice.current.userInterfaceIdiom == .phone{
            self.userInterfaceIdiom = .phone
        }else{
            self.userInterfaceIdiom = .not_phone
        }
        
        // unowned self because we unregister before self becomes invalid
        _observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] text in
            guard let device = text.object as? UIDevice else {
                return
            }
            if device.orientation.isPortrait {
                self.orientation = .portrait
            }
            else if device.orientation.isLandscape {
                self.orientation = .landscape
            }
        }
    }
    
    deinit {
        if let observer = _observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
#else
final class OrientationInfo: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }
    
    enum UserInterfaceIdiom {
        case phone
        case not_phone
    }
    
    @Published var orientation: Orientation
    @Published var userInterfaceIdiom: UserInterfaceIdiom
    
    init() {
        self.orientation = .landscape
        self.userInterfaceIdiom = .not_phone
    }
    
    deinit {
    }
}
#endif

//
//  UserSettings.swift
//  UserSettings
//
//  Created by Ethan Lipnik on 8/30/21.
//

import Combine
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class UserSettings: ObservableObject {
    static let `default` = UserSettings()
    
    @Published var shouldLoadFavicon: Bool = {
        return !UserDefaults.group.bool(forKey: "shouldNotLoadFavicon")
    }() {
        didSet {
            UserDefaults.group.set(!shouldLoadFavicon, forKey: "shouldNotLoadFavicon")
            
            if !shouldLoadFavicon {
                shouldShowFaviconInList = false
            }
        }
    }
    
    @Published var shouldShowFaviconInList: Bool = {
        return UserDefaults.group.bool(forKey: "shouldShowFaviconInList")
    }() {
        didSet {
            UserDefaults.group.set(shouldShowFaviconInList, forKey: "shouldShowFaviconInList")
        }
    }
    
    @Published var shouldSyncWithiCloud: Bool = {
        return !UserDefaults.group.bool(forKey: "shouldNotSyncWithiCloud")
    }() {
        didSet(oldValue) {
            UserDefaults.group.set(!shouldSyncWithiCloud, forKey: "shouldNotSyncWithiCloud")
            
            guard shouldSyncWithiCloud != oldValue else { return }
            
            PersistenceController.shared.container = .create(withSync: shouldSyncWithiCloud)
            PersistenceController.shared.loadStore()
        }
    }
    
#if os(iOS) && !EXTENSION
    @Published var selectedIcon: String = {
        return UserDefaults.group.string(forKey: "selectedIcon") ?? "Default"
    }() {
        didSet {
            UserDefaults.group.set(selectedIcon, forKey: "selectedIcon")
            
            UIApplication.shared.setAlternateIconName(selectedIcon != "Default" ? selectedIcon : nil)
        }
    }
#else
    var selectedIcon: String {
        get {
            return "Default"
        }
    }
#endif
    
#if !EXTENSION
    @Published var colorScheme: Int = {
        return UserDefaults.group.integer(forKey: "colorScheme")
    }() {
        didSet(oldValue) {
            UserDefaults.group.set(colorScheme, forKey: "colorScheme")
            
            guard colorScheme != oldValue else { return }
            updateColorScheme()
        }
    }
    
    func updateColorScheme(shouldAnimate animate: Bool = true) {
#if os(iOS)
        let windows = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
        
        windows.forEach({ window in
            if animate {
                UIView.transition (with: window, duration: 0.3, options: .transitionCrossDissolve, animations: { [colorScheme] in
                    window.overrideUserInterfaceStyle = .fromInteger(colorScheme)
                }, completion: nil)
            } else {
                window.overrideUserInterfaceStyle = .fromInteger(colorScheme)
            }
        })
#elseif os(macOS)
        NSApplication.shared.windows.forEach({ $0.appearance = .fromInteger(colorScheme) })
#endif
    }
#endif
    
    init() {
#if !EXTENSION
        updateColorScheme()
#endif
    }
}

#if os(iOS)
extension UIUserInterfaceStyle {
    static func fromInteger(_ int: Int) -> UIUserInterfaceStyle {
        print(int)
        switch int {
        case 0:
            return .unspecified
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return .unspecified
        }
    }
}
#elseif os(macOS)
extension NSAppearance {
    static func fromInteger(_ int: Int) -> NSAppearance? {
        print(int)
        switch int {
        case 0:
            return .init()
        case 1:
            return .init(named: .aqua)
        case 2:
            return .init(named: .darkAqua)
        default:
            return .init()
        }
    }
}
#endif

extension UserDefaults {
    static var group: UserDefaults {
        return UserDefaults(suiteName: "group.OpenSesame.ethanlipnik")!
    }
}

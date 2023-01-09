import Foundation
import ServiceManagement
import os.log

public struct LoginItemKit {
    public enum LaunchState {
        /// Not in login items.
        case none
        /// Launch with *Hide* property checked.
        case hide
        /// Launch with *Hide* property unchecked.
        case show
    }
    
    private static let bundleURL = URL(fileURLWithPath: Bundle.main.bundlePath) as CFURL
    
    @available(macOS 11, *)
    private static let logger = Logger(subsystem: Bundle.main.bundlePath, category: "LoginItemKit")
    
    // https://github.com/Clipy/LoginServiceKit/blob/master/Lib/LoginServiceKit/LoginServiceKit.swift
    private static var loginItems: (list: LSSharedFileList, items: [LSSharedFileListItem])? {
        guard let list = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue() else {
            return nil
        }
        return (list, (LSSharedFileListCopySnapshot(list, nil)?.takeRetainedValue() as? [LSSharedFileListItem]) ?? [])
    }
    
    private static func addToLoginItems(hide: Bool) {
        if let (list, items) = loginItems {
            // https://stackoverflow.com/a/5598992
            let inProperties = CFDictionaryCreateMutable(nil, 1, nil, nil)
            CFDictionaryAddValue(inProperties, Unmanaged.passUnretained(kLSSharedFileListLoginItemHidden.takeRetainedValue()).toOpaque(), Unmanaged.passUnretained(hide ? kCFBooleanTrue : kCFBooleanFalse).toOpaque())
            
            let item = unsafeBitCast(items.last, to: LSSharedFileListItem.self)
            LSSharedFileListInsertItemURL(list, item, nil, nil, bundleURL, inProperties, nil)
        }
    }

    private static func removeFromLoginItems() {
        if let (list, items) = loginItems {
            for item in items {
                if LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() == bundleURL {
                    LSSharedFileListItemRemove(list, item)
                    break
                }
            }
        }
    }
    
    // https://github.com/sindresorhus/LaunchAtLogin-Modern/blob/main/Sources/LaunchAtLogin/LaunchAtLogin.swift
    @available(macOS 13, *)
    private static var openAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status == .enabled {
                        try? SMAppService.mainApp.unregister()
                    }

                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                logger.error("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }

    /// Tertiary launch state respecting the *Hide* property.
    public static var launchState: LaunchState {
        get {
            if #available(macOS 13, *) {
                return openAtLogin ? .show : .none
            } else {
                if let (_, items) = loginItems {
                    for item in items {
                        if LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() == bundleURL {
                            let isHidden = LSSharedFileListItemCopyProperty(item, kLSSharedFileListLoginItemHidden.takeRetainedValue())?.takeRetainedValue() as? Bool
                            return isHidden == true ? .hide : .show
                        }
                    }
                }
                return .none
            }
        }
        
        set {
            if #available(macOS 13, *) {
                openAtLogin = (newValue != .none)
            } else {
                switch newValue {
                case .none: removeFromLoginItems()
                case .hide: addToLoginItems(hide: true)
                case .show: addToLoginItems(hide: false)
                }
            }
        }
    }
    
    /// Binary launch state ignoring the *Hide* property.
    public static var launchAtLogin: Bool {
        get { return launchState != .none }
        set { launchState = newValue ? .show : .none }
    }
}

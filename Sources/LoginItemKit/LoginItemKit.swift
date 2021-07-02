import Foundation


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
    
    private static func addToLoginItems(hide: Bool) {

        if let itemList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue() {

            // https://stackoverflow.com/a/5598992
            let inProperties = CFDictionaryCreateMutable(nil, 1, nil, nil)
            CFDictionaryAddValue(inProperties, Unmanaged.passUnretained(kLSSharedFileListLoginItemHidden.takeRetainedValue()).toOpaque(), Unmanaged.passUnretained(hide ? kCFBooleanTrue : kCFBooleanFalse).toOpaque())

            LSSharedFileListInsertItemURL(itemList, nil, nil, nil, bundleURL, inProperties, nil)

        }

    }

    private static func removeFromLoginItems() {

        if let itemList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue(), let items = LSSharedFileListCopySnapshot(itemList, nil)?.takeRetainedValue() as? [LSSharedFileListItem] {

            for item in items {

                if LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() == bundleURL {

                    LSSharedFileListItemRemove(itemList, item)
                    break

                }

            }

        }

    }

    /// Tertiary launch state respecting the *Hide* property.
    public static var launchState: LaunchState {
        
        get {

            if let itemList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue(), let items = LSSharedFileListCopySnapshot(itemList, nil)?.takeRetainedValue() as? [LSSharedFileListItem] {

                for item in items {

                    if LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() == bundleURL {

                        let isHidden = LSSharedFileListItemCopyProperty(item, kLSSharedFileListLoginItemHidden.takeRetainedValue())?.takeRetainedValue() as? Bool
                        return isHidden == true ? .hide : .show

                    }

                }

            }

            return .none
            
        }
        
        set {
            
            switch newValue {
            
            case .none: removeFromLoginItems()
            case .hide: addToLoginItems(hide: true)
            case .show: addToLoginItems(hide: false)
            
            }
            
        }

    }
    
    /// Binary launch state ignoring the *Hide* property.
    public static var launchAtLogin: Bool {
        
        get { return launchState != .none }
        
        set { launchState = newValue ? .show : .none }
        
    }

}

import Foundation

public struct LoginItemKit {
    
    private static let bundleURL = URL(fileURLWithPath: Bundle.main.bundlePath) as CFURL
    
    private static var isInLoginItems: Bool {

        if let itemList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList?, let items = LSSharedFileListCopySnapshot(itemList, nil).takeRetainedValue() as? [LSSharedFileListItem] {
            
            for item in items {
                
                if LSSharedFileListItemCopyResolvedURL(item, 0, nil).takeRetainedValue() == bundleURL {
                    
                    return true
                    
                }
                
            }
            
        }
        
        return false
        
    }

    private static func addToLoginItems() {
        
        if !isInLoginItems {
            
            if let itemList = LSSharedFileListCreate( nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList?, let items = LSSharedFileListCopySnapshot(itemList, nil).takeRetainedValue() as? [LSSharedFileListItem] {
                    
                LSSharedFileListInsertItemURL(itemList, items.last, nil, nil, bundleURL, nil, nil)

            }
            
        }
        
    }

    private static func removeFromLoginItems() {
        
        if isInLoginItems {
            
            if let itemList = LSSharedFileListCreate( nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileList?, let items = LSSharedFileListCopySnapshot(itemList, nil).takeRetainedValue() as? [LSSharedFileListItem] {
                
                for item in items {
                    
                    if LSSharedFileListItemCopyResolvedURL(item, 0, nil).takeRetainedValue() == bundleURL {
                        
                        LSSharedFileListItemRemove(itemList, item)
                        break
                        
                    }
                    
                }

            }
            
        }

    }
    
    public static var launchAtLogin: Bool {

        get { return isInLoginItems }

        set { newValue ? addToLoginItems() : removeFromLoginItems() }

    }

}

struct K {
    
    static let appName = "Notes"
    static let itemCell = "ItemCell"
    static let cellNibName = "ItemCell"
    static let rootFolderName = "Root"
    static let defaultNoteName = "New Note"
    static let maxNoteTitleLength = 20
    
    struct Icons {
        static let folder = "folder"
        static let note = "doc.text"
        static let trash = "trash"
        static let edit = "pencil"
    }
    
    struct Labels {
        struct Folder {
            static let alertTitle = "Add New Folder"
            static let actionTitle = "Add Folder"
            static let placeholder = "Folder Name"
        }
        
        struct Edit {
            static let alertTitle = "Edit Name"
            static let actionTitle = "Edit"
        }

    }
    
}

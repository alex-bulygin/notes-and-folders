struct K {
    static let itemCell = "ItemCell"
    static let cellNibName = "ItemCell"
    
    struct Segues {
        static let goToNote = "GoToNote"
    }
    
    struct Icons {
        static let folder = "folder"
        static let note = "doc.text"
    }
    
    struct ItemTypes {
        static let folder = "Folder"
        static let note = "Note"
        
        struct Folder {
            static let alertTitle = "Add New Folder"
            static let actionTitle = "Add Folder"
            static let placeholder = "Folder Name"
        }
    
        struct Note {
            static let alertTitle = "Add New Note"
            static let actionTitle = "Add Note"
            static let placeholder = "Note Title"
        }
    }
}

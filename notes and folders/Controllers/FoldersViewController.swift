//
//  ViewController.swift
//  notes and folders
//
//  Created by Mac on 14.03.2020.
//  Copyright © 2020 Moonlight. All rights reserved.
//

import UIKit
import CoreData

class FoldersViewController: UIViewController, Storyboarded {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var coordinator: MainCoordinator?
    
    var folders = [Folder]()
    var notes = [Note]()
    var currentFolder: Folder?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.itemCell)
        tableView.dataSource = self
        tableView.delegate = self
        hideKeyboardWhenTappedAround()
        
        if currentFolder == nil {
            setupRootFolder()
        }
         
//        deleteAll()
//        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Perform search if the search bar isn't empty, otherwise load folder's contents
        if searchBar.text != "" {
            searchNotes(with: searchBar.text!, in: currentFolder)
        } else {
            loadItems(in: currentFolder)
            refreshTableView()
        }
    }
    
    
    func setupRootFolder() {
        
        loadItems()
        
        // If there is already a root folder in the context use it, otherwise, create one
        for folder in folders {
            if folder.name == K.rootFolderName {
                currentFolder = folder
                return
            }
        }
        
        currentFolder = Folder(context: context)
        currentFolder!.name = K.rootFolderName
        currentFolder!.id = UUID().uuidString
        saveContext()
    }
    
        
    func sortFoldersAndNotes() {
        
        // Sort folders by name and notes by date
        folders.sort {
            $0.name! < $1.name!
        }
        notes.sort {
            $0.modified! > $1.modified!
        }
    }
    
    
    func refreshTableView() {
        
        // Perform sort and refresh title and contents in the main thread
        sortFoldersAndNotes()
        
        DispatchQueue.main.async {
            if let folder = self.currentFolder {
                self.navBar.title = folder.name == K.rootFolderName ? K.appName : folder.name
            }
            
            self.tableView.reloadData()
        }
    }
    
        
    //MARK: - Core Data
    
    func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    
    func loadItems(in folder: Folder? = nil) {
        
        // Load items to 'folders' and 'notes' arrays
        // If there is no folder as a parameter load all items in the context
        
        let folders_request: NSFetchRequest<Folder> = Folder.fetchRequest()
        let notes_request: NSFetchRequest<Note> = Note.fetchRequest()
        
        let predicate: NSPredicate
        
        if let parentFolder = folder {
            predicate = NSPredicate(format: "parentFolder.id CONTAINS %@", parentFolder.id!)
            folders_request.predicate = predicate
            notes_request.predicate = predicate
        }
        
        do {
            folders = try context.fetch(folders_request)
            notes = try context.fetch(notes_request)
        } catch {
            print(error)
        }
    }
    
    
    func loadNotes(with request: NSFetchRequest<Note>) {
        
        // Used to perform search
        do {
            folders = []
            notes = try context.fetch(request)
        } catch {
            print(error)
        }
    }
    
    
    func deleteAll() {
        
        // Vipe all items from context
        loadItems()
        
        for folder in folders {
            context.delete(folder)
        }
        folders = []
        
        for note in notes {
            context.delete(note)
        }
        notes = []
        
        saveContext()
    }
    
    
    //MARK: - @IBActions
    
    @IBAction func addFolderPressed(_ sender: UIBarButtonItem) {
        
        // Create an alert with a text field for a folder's name
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: K.Labels.Folder.alertTitle, message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: K.Labels.Folder.actionTitle, style: .default) { (action) in
            
            // When 'Add Folder' button pressed, create a new folder, add it to the context and refresh the view
            if textField.text != "" {
                
                let newFolder = Folder(context: self.context)
                newFolder.name = textField.text!
                
                if let parentFolder = self.currentFolder {
                    newFolder.parentFolder = parentFolder
                }
                newFolder.id = UUID().uuidString
                
                self.folders.append(newFolder)
                self.saveContext()
                self.refreshTableView()
            }
        }
        
        alert.addAction(action)
        alert.addTextField { (field) in
            textField = field
            textField.placeholder = K.Labels.Folder.placeholder
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func createNotePressed(_ sender: UIButton) {
        
        // Create a new note, add it to the context and open editor
        let newNote = Note(context: context)
        newNote.title = K.defaultNoteName
        
        if let parentFolder = currentFolder {
            newNote.parentFolder = parentFolder
        }
        
        newNote.modified = Date()
        notes.append(newNote)
        saveContext()
        
        coordinator?.openNoteEditor(with: newNote)
    }
}


//MARK: - UITableView

extension FoldersViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count + notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.itemCell, for: indexPath) as! ItemCell
        
        // Listing folders and then notes
        if indexPath.row < folders.count {
            cell.label.text = folders[indexPath.row].name
            cell.icon.image = UIImage(systemName: K.Icons.folder)
        } else {
            cell.label.text = notes[indexPath.row - folders.count].title
            cell.icon.image = UIImage(systemName: K.Icons.note)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Call respective coordinator methods
        if indexPath.row < folders.count {
            coordinator?.openFolder(with: folders[indexPath.row])
        } else {
            coordinator?.openNoteEditor(with: notes[indexPath.row - folders.count])
        }
    }
    
    
    //MARK: - Swipe actions
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Register swipe actions for folders and notes
        let edit = editName(at: indexPath)
        let delete = deleteItem(at: indexPath)
        
        if indexPath.row < folders.count {
            return UISwipeActionsConfiguration(actions: [delete, edit])
        } else {
            return UISwipeActionsConfiguration(actions: [delete])
        }
        
    }
    
    
    func editName(at indexPath: IndexPath) -> UIContextualAction {
        
        // Create an alert with a text field for a folder's name
        
        let action = UIContextualAction(style: .normal, title: "Edit") { (action, view, completion) in
            
            var textField = UITextField()
            
            let alert = UIAlertController(title: K.Labels.Edit.alertTitle, message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: K.Labels.Edit.actionTitle, style: .default) { (action) in
                
                // When 'Edit Name' button pressed, change the folder's name, save the context and refresh the view
                
                if textField.text != "" {
                    
                    let folder = self.folders[indexPath.row]
                    folder.name = textField.text!
                    self.folders[indexPath.row] = folder
                    
                    self.saveContext()
                    self.refreshTableView()
                }
            }
            
            alert.addAction(action)
            alert.addTextField { (field) in
                textField = field
                textField.text = self.folders[indexPath.row].name // Load folder's current name to the text field
            }
            
            self.present(alert, animated: true, completion: nil)
            
            completion(true)
        }
        
        action.image = UIImage(systemName: K.Icons.edit)
        action.backgroundColor = .systemGreen
        return action
    }
    
    
    func deleteItem(at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            
            // Delete folder and all its contents
            if indexPath.row < self.folders.count {
                
                var itemsToDelete = self.findAllItems(in: self.folders[indexPath.row])
                itemsToDelete.append(self.folders[indexPath.row])
                
                for item in itemsToDelete {
                    self.context.delete(item)
                }
                
                self.loadItems(in: self.currentFolder)
                
            } else {
                // Delete note
                self.context.delete(self.notes[indexPath.row - self.folders.count])
                self.notes.remove(at: indexPath.row - self.folders.count)
            }
            
            DispatchQueue.main.async {
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            self.saveContext()
            
            completion(true)
        }
        
        action.image = UIImage(systemName: K.Icons.trash)
        action.backgroundColor = .systemRed
        return action
    }
}


//MARK: - Search

extension FoldersViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Perform a search if the search bar isn't empty
        if searchBar.text != "" {
            searchNotes(with: searchBar.text!, in: currentFolder)
        }
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // If the search bar is empty load current folder's contents, otherwise perform a search
        if searchText == "" {
            loadItems(in: currentFolder)
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
            refreshTableView()
            
        } else {
            searchNotes(with: searchText, in: currentFolder)
        }
    }
    
    
    func searchNotes(with text: String, in folder: Folder?) {
        
        guard folder != nil else { return }
                
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let predicate  = NSPredicate(format: "text CONTAINS[cd] %@", text)
        
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "modified", ascending: false)]
        
        // Load all notes matching request to 'notes' array
        loadNotes(with: request)
        
        // Get all items within given folder
        let allItemsInFolder = findAllItems(in: folder!)
        
        // If the note isn't in given folder's contents remove it from 'notes' array
        for (index, note) in notes.enumerated() {
            if allItemsInFolder.firstIndex(of: note as NSManagedObject) == nil {
                notes.remove(at: index)
            }
        }
        
        // Load results
        refreshTableView()
        
    }
    
    // Recursive
    func findAllItems(in folder: Folder) -> [NSManagedObject] {
        
        var items = [NSManagedObject]()
        
        if let folders = folder.folders {
            for f in folders {
                items.append(f as! Folder)
                items.append(contentsOf: findAllItems(in: f as! Folder))
            }
        }
        
        if let notes = folder.notes {
            for n in notes {
                items.append(n as! Note)
            }
        }
        
        return items
    }
}


//MARK: - Hide Keyboard

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}


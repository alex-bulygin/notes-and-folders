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
        
        if currentFolder == nil {
            setupRootFolder()
        }

        hideKeyboardWhenTappedAround()
        
//        loadItems()
//        deleteAll()
//        loadItems()
//        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if searchBar.text != "" {
            search(for: searchBar.text!)
        } else {
            loadItems(in: currentFolder)
            refreshTableView()
        }
    }
    
    
    func sortFoldersAndNotes() {
        folders.sort {
            $0.name! < $1.name!
        }
        notes.sort {
            $0.modified! > $1.modified!
        }
    }
    
    
    func refreshTableView() {
        sortFoldersAndNotes()
        
        DispatchQueue.main.async {
            if let folder = self.currentFolder {
                self.navBar.title = folder.name == K.rootFolderName ? K.appName : folder.name
            }
            
            self.tableView.reloadData()
        }
    }
    
    
    func setupRootFolder() {
        
        loadItems()
        
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
    
    
    //MARK: - Core Data
    
    func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    
    func loadItems(in folder: Folder? = nil) {
        
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
    
    func loadItems(with request: NSFetchRequest<Note>) {
        
        do {
            folders = []
            notes = try context.fetch(request)
        } catch {
            print(error)
        }
    }
    
    
    func deleteAll() {
        
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
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: K.Labels.Folder.alertTitle, message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: K.Labels.Folder.actionTitle, style: .default) { (action) in
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
    
    
    @IBAction func navBackButtonPressed(_ sender: UIBarButtonItem) {
        currentFolder = currentFolder?.parentFolder
        loadItems(in: currentFolder)
        refreshTableView()
    }
}


//MARK: - UITableView

extension FoldersViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count + notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.itemCell, for: indexPath) as! ItemCell
        
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
        
        if indexPath.row < folders.count {
            coordinator?.openFolder(with: folders[indexPath.row])
        } else {
            if let indexPath = tableView.indexPathForSelectedRow {
                coordinator?.openNoteEditor(with: notes[indexPath.row - folders.count])
            }
        }
    }
    
    
    //MARK: - Swipe actions
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = editName(at: indexPath)
        let delete = deleteItem(at: indexPath)
        
        if indexPath.row < folders.count {
            return UISwipeActionsConfiguration(actions: [delete, edit])
        } else {
            return UISwipeActionsConfiguration(actions: [delete])
        }
        
    }
    
    
    func editName(at indexPath: IndexPath) -> UIContextualAction {
        
        let action = UIContextualAction(style: .normal, title: "Edit") { (action, view, completion) in
            
            var textField = UITextField()
            
            let alert = UIAlertController(title: K.Labels.Edit.alertTitle, message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: K.Labels.Edit.actionTitle, style: .default) { (action) in
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
                textField.text = self.folders[indexPath.row].name
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
            
            if indexPath.row < self.folders.count {
                
                self.context.delete(self.folders[indexPath.row])
                self.folders.remove(at: indexPath.row)
                
            } else {
                self.context.delete(self.notes[indexPath.row - self.folders.count])
                self.notes.remove(at: indexPath.row - self.folders.count)
            }
            
            DispatchQueue.main.async {
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            completion(true)
        }
        
        action.image = UIImage(systemName: K.Icons.trash)
        action.backgroundColor = .systemRed
        return action
    }
    
}


//MARK: - UISearchBarDelegate

extension FoldersViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            search(for: searchBar.text!)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            loadItems(in: currentFolder)
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
            refreshTableView()
            
        } else {
            search(for: searchText)
        }
    }
    
    func search(for text: String) {
        
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        
        let predicate  = NSPredicate(format: "text CONTAINS[cd] %@", text)
        
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "modified", ascending: false)]
        
        loadItems(with: request)
        
        refreshTableView()
        
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


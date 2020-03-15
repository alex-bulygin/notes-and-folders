//
//  ViewController.swift
//  notes and folders
//
//  Created by Mac on 14.03.2020.
//  Copyright © 2020 Moonlight. All rights reserved.
//

import UIKit
import CoreData

class FoldersController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var navBackButton: UIBarButtonItem!
    
    var folders = [Folder]()
    var notes = [Note]()
    var currentFolder: Folder?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.itemCell)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        navBackButton.isEnabled = false
        
        setupRootFolder()
        loadItems(in: currentFolder)
        refreshTableView()
        
        //        loadItems()
        //        deleteAll()
        //        loadItems()
        //        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadItems(in: currentFolder)
        refreshTableView()
        
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
                if folder.name == K.rootFolderName {
                    self.navBar.title = K.appName
                    self.navBackButton.isEnabled = false
                } else {
                    self.navBar.title = folder.name
                    self.navBackButton.isEnabled = true
                }
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
    
    
//    func addItem(ofType itemType: String) {
//
//        let alertTitle = K.ItemTypes.Folder.alertTitle
//        actionTitle = K.ItemTypes.Folder.actionTitle
//        placeholder = K.ItemTypes.Folder.placeholder
//
//        if itemType == K.ItemTypes.folder {
//            alertTitle = K.ItemTypes.Folder.alertTitle
//            actionTitle = K.ItemTypes.Folder.actionTitle
//            placeholder = K.ItemTypes.Folder.placeholder
//        } else if itemType == K.ItemTypes.note {
//            alertTitle = K.ItemTypes.Note.alertTitle
//            actionTitle = K.ItemTypes.Note.actionTitle
//            placeholder = K.ItemTypes.Note.placeholder
//        }
//
//        var textField = UITextField()
//
//        let alert = UIAlertController(title: alertTitle, message: "", preferredStyle: .alert)
//        let action = UIAlertAction(title: actionTitle, style: .default) { (action) in
//            if textField.text != "" {
//
//                if itemType == K.ItemTypes.folder {
//                    let newFolder = Folder(context: self.context)
//                    newFolder.name = textField.text!
//                    if let parentFolder = self.currentFolder {
//                        newFolder.parentFolder = parentFolder
//                    }
//                    newFolder.id = UUID().uuidString
//                    self.folders.append(newFolder)
//
//                } else if itemType == K.ItemTypes.note {
//                    let newNote = Note(context: self.context)
//                    newNote.title = textField.text!
//                    if let parentFolder = self.currentFolder {
//                        newNote.parentFolder = parentFolder
//                    }
//                    newNote.modified = Date()
//                    self.notes.append(newNote)
//                }
//
//                self.saveContext()
//                self.refreshTableView()
//            }
//        }
//
//        alert.addAction(action)
//        alert.addTextField { (field) in
//            textField = field
//            textField.placeholder = placeholder
//        }
//
//        present(alert, animated: true, completion: nil)
//    }
//
    
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
        
        performSegue(withIdentifier: K.Segues.goToNote, sender: self)
        
    
    }
    
    @IBAction func navBackButtonPressed(_ sender: UIBarButtonItem) {
        currentFolder = currentFolder?.parentFolder
        loadItems(in: currentFolder)
        refreshTableView()
        
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! NotesController
        if let indexPath = tableView.indexPathForSelectedRow {
            destVC.note = notes[indexPath.row - folders.count]
        } else {
            destVC.note = notes.last
        }
    }
}


//MARK: - UITableView

extension FoldersController: UITableViewDataSource, UITableViewDelegate {
    
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
            
            currentFolder = folders[indexPath.row]
            loadItems(in: currentFolder)
            refreshTableView()
            
        } else {
            performSegue(withIdentifier: K.Segues.goToNote, sender: self)
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


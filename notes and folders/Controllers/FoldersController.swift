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
    
    var folders = [Folder]()
    var notes = [Note]()
    var currentFolder: Folder?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.itemCell)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        loadItems()
        //        deleteAll()
        //        loadItems()
        
    }
    
    func reloadItems() {
        
        folders.sort {
            $0.name! < $1.name!
        }
        
        notes.sort {
            $0.modified! > $1.modified!
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    
    //MARK: - Core Data
    
    func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func loadItems() {
        
        let folders_request: NSFetchRequest<Folder> = Folder.fetchRequest()
        let notes_request: NSFetchRequest<Note> = Note.fetchRequest()
        
        do {
            folders = try context.fetch(folders_request)
            notes = try context.fetch(notes_request)
        } catch {
            print(error)
        }
        
        reloadItems()
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
    
    //MARK: - Actions
    
    func addItem(ofType itemType: String) {
        
        var alertTitle = String()
        var actionTitle = String()
        var placeholder = String()
        
        if itemType == K.ItemTypes.folder {
            alertTitle = K.ItemTypes.Folder.alertTitle
            actionTitle = K.ItemTypes.Folder.actionTitle
            placeholder = K.ItemTypes.Folder.placeholder
        } else if itemType == K.ItemTypes.note {
            alertTitle = K.ItemTypes.Note.alertTitle
            actionTitle = K.ItemTypes.Note.actionTitle
            placeholder = K.ItemTypes.Note.placeholder
        }
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: alertTitle, message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default) { (action) in
            if textField.text != "" {
                
                if itemType == K.ItemTypes.folder {
                    let newFolder = Folder(context: self.context)
                    newFolder.name = textField.text!
                    if let parentFolder = self.currentFolder {
                        newFolder.parentFolder = parentFolder
                    }
                    self.folders.append(newFolder)
                    
                } else if itemType == K.ItemTypes.note {
                    let newNote = Note(context: self.context)
                    newNote.title = textField.text!
                    if let parentFolder = self.currentFolder {
                        newNote.parentFolder = parentFolder
                    }
                    newNote.modified = Date()
                    self.notes.append(newNote)
                    
                }
                
                self.saveContext()
                self.reloadItems()
            }
        }
        
        alert.addAction(action)
        alert.addTextField { (field) in
            textField = field
            textField.placeholder = placeholder
        }
        
        present(alert, animated: true, completion: nil)
        
        saveContext()
        
    }
    
    @IBAction func addFolderPressed(_ sender: UIBarButtonItem) {
        addItem(ofType: K.ItemTypes.folder)
    }
    
    @IBAction func createNotePressed(_ sender: UIButton) {
        addItem(ofType: K.ItemTypes.note)
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
        if indexPath.row >= folders.count {
           // print(notes[indexPath.row - folders.count].title)
            performSegue(withIdentifier: K.Segues.goToNote, sender: self)
            
        }
        
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! NotesController
        let indexPath = tableView.indexPathForSelectedRow!
        
        destVC.note = notes[indexPath.row - folders.count]
    }
    
    
    
    
    
}


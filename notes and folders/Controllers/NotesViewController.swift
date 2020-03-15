//
//  NotesController.swift
//  notes and folders
//
//  Created by Mac on 14.03.2020.
//  Copyright © 2020 Moonlight. All rights reserved.
//


import UIKit

class NotesViewController: UIViewController, Storyboarded{
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var text: UITextView!
    
    var coordinator: MainCoordinator?
    
    var note: Note?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        text.delegate = self
        
        navBar.title = note?.title
        text.text = note?.text
        
    }
    
    
    func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    
    func generateTitle(from text: String) -> String {
            
        var title = text
        
        if let index = text.firstIndex(of: "\n") {
            title = String(text[..<index])
        }

        if title.count > K.maxNoteTitleLength {
            title = title.prefix(K.maxNoteTitleLength) + "..."
        }
        
        if title == "" {
            title = K.defaultNoteName
        }

        return title
    }

}


//MARK: - UITextViewDelegate

extension NotesViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
        note?.text = text.text
        note?.title = generateTitle(from: text.text)
        note?.modified = Date()
        saveContext()
    }
    
}

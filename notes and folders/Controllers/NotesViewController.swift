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
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NotesViewController.handleKeyboardDidShow(notification:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NotesViewController.handleKeybolardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc func handleKeyboardDidShow(notification: NSNotification) {
        guard let keyboardRect = notification
            .userInfo![UIResponder.keyboardFrameEndUserInfoKey]
            as? NSValue else { return }

        let frameKeyboard = keyboardRect.cgRectValue

        text.contentInset = UIEdgeInsets(
            top: 0.0,
            left: 0.0,
            bottom: frameKeyboard.size.height,
            right: 0.0
        )

        view.layoutIfNeeded()
    }

    @objc func handleKeybolardWillHide() {
        text.contentInset = .zero
    }
    
    
    func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    
    func generateTitleForNote(from text: String) -> String {
            
        var title = text.trimmingCharacters(in: .whitespaces)
        
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
        note?.title = generateTitleForNote(from: text.text)
        note?.modified = Date()
        saveContext()
    }
    
}

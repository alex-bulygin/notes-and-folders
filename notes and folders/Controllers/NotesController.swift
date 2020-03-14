//
//  NotesController.swift
//  notes and folders
//
//  Created by Mac on 14.03.2020.
//  Copyright © 2020 Moonlight. All rights reserved.
//

import UIKit

class NotesController: UIViewController {

    var note: Note?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var text: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        text.delegate = self
        
        navBar.title = note?.title
        text.text = note?.text
    }
    
    
    
    func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension NotesController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
        note?.text = text.text
        note?.modified = Date()
        saveContext()
    }
    
}

//
//  MainCoordinator.swift
//  notes and folders
//
//  Created by Mac on 15.03.2020.
//  Copyright © 2020 Moonlight. All rights reserved.
//

import UIKit

class MainCoordinator: NSObject, Coordinator {

    var childCoordinators = [Coordinator]()
    
    var navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = FoldersController.instantiate()
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: false)
    }
    
    func openFolder(with currentFolder: Folder) {
        let vc = FoldersController.instantiate()
        vc.coordinator = self
        vc.currentFolder = currentFolder
        navigationController.pushViewController(vc, animated: true)
    }
    
    func openNoteEditor(with note: Note) {
        let vc = NotesController.instantiate()
        vc.coordinator = self
        vc.note = note
        navigationController.pushViewController(vc, animated: true)
    }
    
}



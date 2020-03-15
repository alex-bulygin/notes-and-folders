//
//  Coordinator.swift
//  notes and folders
//
//  Created by Mac on 15.03.2020.
//  Copyright © 2020 Moonlight. All rights reserved.
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

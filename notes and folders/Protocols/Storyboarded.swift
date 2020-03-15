//
//  Storyboarded.swift
//  notes and folders
//
//  Created by Mac on 15.03.2020.
//  Copyright © 2020 Moonlight. All rights reserved.
//

import UIKit

protocol Storyboarded {
    static func instantiate() -> Self
}

extension Storyboarded where Self: UIViewController {
    static func instantiate() -> Self {
        let id = String(describing: self)
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        return storyboard.instantiateViewController(withIdentifier: id) as! Self
    }
}

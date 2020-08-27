//
//  Ship.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechiporenko on 10/9/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import Foundation


struct Ship{
    
    var isRotateRight = true
    var coordinates = [Int]()
    var usedCoordinates = [Int]()
    var lockedCoordinates = [Int]()
    var isDestroyed = false
    var type = 0
    
    init(rotation: Bool , coordinates: [Int] , type: Int , lockedCoordinates: [Int] , isDestroyed : Bool)
    {
        isRotateRight = rotation
        self.coordinates = coordinates
        self.type = type
        self.lockedCoordinates = lockedCoordinates
        self.isDestroyed = isDestroyed
    }
    
    mutating func addUsedCoordinate(coordinate : Int){
        usedCoordinates.append(coordinate)
    }
    
}

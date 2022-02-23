//
//  Ship.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 10/9/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import Foundation

// class that represents ship
class Ship: Codable{
    
    private(set) var isRotateRight = true
    private(set) var coordinates = [Int]()
    // coordinates which was guessed by player
    private(set) var usedCoordinates: [Int]?
    // when ship will be destroyed, this coordinates will not be available for player to guess, cuz ships can`t
    // be so close to each other
    private(set) var lockedCoordinates = [Int]()
    var isDestroyed = false
    // 1 - single-deck ship, 2 - double-deck ship etc
    private(set) var type = 0
    
    init(rotation: Bool , coordinates: [Int] , type: Int , lockedCoordinates: [Int] , isDestroyed : Bool, usedCoordinates: [Int] = [Int]())
    {
        isRotateRight = rotation
        self.coordinates = coordinates
        self.type = type
        self.lockedCoordinates = lockedCoordinates
        self.isDestroyed = isDestroyed
        self.usedCoordinates = usedCoordinates
    }
    
    func addUsedCoordinate(coordinate : Int){
        if usedCoordinates == nil {
            usedCoordinates = [Int]()
        }
        usedCoordinates?.append(coordinate)
    }
    
}

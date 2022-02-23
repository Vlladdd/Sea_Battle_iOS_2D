//
//  Player.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 11/12/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import Foundation


// class that represents player
class Player: Codable{
    
    // ready = true when player placed his ships
    var ready = false
    // name and email of player from his google account; email is using to determine
    // whether the game was created by this user
    var email = ""
    var name = ""
    // ships of player and all data associated to them
    var playerShips = PlayerShips()
    // how much of THIS player`s ships was destroyed
    var destroyedShips = 0
    // coordinates which THIS player already used to try guess where the ship is;
    // in UI they are red if there is no ship and green if this is one of the ship`s coordinate
    var usedCoordinates:[Int]?
    
}

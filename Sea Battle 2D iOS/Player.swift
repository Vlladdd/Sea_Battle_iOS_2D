//
//  Player.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechiporenko on 11/12/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import Foundation


class Player{
    
    var playerShips : PlayerShips?
    var hit : Bool?
    var destroyedShips = 0
    var usedCoordinates:[Int] = [200]
    
    init(){
        playerShips = PlayerShips()
    }
    
    
}

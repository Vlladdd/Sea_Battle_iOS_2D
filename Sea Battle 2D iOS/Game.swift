//
//  Game.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechiporenko on 11/12/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import Foundation
import Starscream


class Game {
    var gamemode : Int?
    
    var player_1 : Player?
    var player_2 : Player?
    
    var win : String?
    var name : String?
    var gamesNames : [String] = ["a"]

    
    
    init(gamemode : Int){
        player_1 = Player()
        player_2 = Player()
        self.gamemode = gamemode
    }
    
    init(game : [String : Any]) {
        gamemode = game["gamemode"] as? Int
        name = game["name"] as? String
        var player1Ships : [Ship] = []
        var player2Ships : [Ship] = []
        player_1 = Player()
        player_2 = Player()
        for b in game["player1Ships"] as! [[String:Any]]{
            let rotation = b["isRotateRight"] as! Bool
            let type = b["type"] as! Int
            let coordinates = b["coordinates"] as! [Int]
            let isDestroyed = b["isDestroyed"] as! Bool
            let lockedCoordinates = b["lockedCoordinates"] as! [Int]
            player1Ships.append(Ship(rotation: rotation, coordinates: coordinates, type: type, lockedCoordinates: lockedCoordinates , isDestroyed: isDestroyed))
        }
        for b in game["player2Ships"] as! [[String:Any]]{
            let rotation = b["isRotateRight"] as! Bool
            let isDestroyed = b["isDestroyed"] as! Bool
            let type = b["type"] as! Int
            let coordinates = b["coordinates"] as! [Int]
            let lockedCoordinates = b["lockedCoordinates"] as! [Int]
            player2Ships.append(Ship(rotation: rotation, coordinates: coordinates, type: type, lockedCoordinates: lockedCoordinates , isDestroyed: isDestroyed))
        }
        player_1?.playerShips?.ships = player1Ships
        player_2?.playerShips?.ships = player2Ships
        if gamemode != 2 {
        player_1?.usedCoordinates = game["player1UsedCoordinates"] as! [Int]
        player_2?.usedCoordinates = game["player2UsedCoordinates"] as! [Int]
        }
    }
    
    init(game1 : [String : Any]) {
        gamemode = game1["gamemode"] as? Int
        name = game1["name"] as? String
        var player1Ships : [Ship] = []
        player_1 = Player()
        player_2 = Player()
        for b in game1["player1Ships"] as! [[String:Any]]{
            let rotation = b["isRotateRight"] as! Bool
            let type = b["type"] as! Int
            let coordinates = b["coordinates"] as! [Int]
            let isDestroyed = b["isDestroyed"] as! Bool
            let lockedCoordinates = b["lockedCoordinates"] as! [Int]
            player1Ships.append(Ship(rotation: rotation, coordinates: coordinates, type: type, lockedCoordinates: lockedCoordinates , isDestroyed: isDestroyed))
        }
        player_1?.playerShips?.ships = player1Ships
    }
    
    func checkForWin() -> Bool{
        if player_2?.destroyedShips == 10 {
            win = "Player1 wins"
            return true
        }
        if player_1?.destroyedShips == 10 {
            win = "Player2 wins"
            return true
        }
        return false
    }
}

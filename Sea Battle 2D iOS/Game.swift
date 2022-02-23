//
//  Game.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 11/12/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import Foundation

// class that represents logic of the game
class Game: Codable{
    
    enum GameMode: String, Codable {
        case singleplayer
        case multiplayer
        case onescreen
        case none
    }
    
    enum GameType: String, Codable {
        case create
        case load
        case join
        // when multiplayer game starts we change her status so this game is not showing in available multiplayer games
        case playing
        case none
    }
    
    enum PlayerStatus: String, Codable {
        case player1
        case player2
        case none
    }
    
    private(set) var gameMode = GameMode.singleplayer
    // if player hit ship
    private(set) var hit = false
    // text when someone win the game
    private(set) var win = ""
    // locked gamesNames for game type
    private(set) var gamesNames : [String]?
    
    // if player destroy ship
    private var shipDestroyed = false
    private var currentOponent: Player {
        if currentPlayerStatus == .player1 {
            return player_2
        }
        else {
            return player_1
        }
    }
    private var oponentShips: PlayerShips {
        if currentPlayerStatus == .player1 {
            return player_2.playerShips
        }
        else {
            return player_1.playerShips
        }
    }
    
    var gameType = GameType.create
    var player_1 = Player()
    var player_2 = Player()
    var name = ""
    var currentPlacingPlayer: PlayerStatus {
        if player_1.ready {
            return .player2
        }
        else {
            return .player1
        }
    }
    var currentPlayerStatus = PlayerStatus.player1
    var currentPlacingShips: PlayerShips {
        if player_1.ready {
            return player_2.playerShips
        }
        else {
            return player_1.playerShips
        }
    }
    
    func encode() throws -> Data {
        try JSONEncoder().encode(self)
    }
    
    // used to place ships randomly
    func randomCoordinates() -> [Int:[Int:Bool]] {
        var coordinates = [1:[Int:Bool](),2:[Int:Bool](),3:[Int:Bool](),4:[Int:Bool]()]
        for x in 1...4{
            for _ in 0...4-x{
                var randomNumber = Int.random(in: Constants.availableFieldCoordinates)
                while coordinates[1]![randomNumber] != nil && coordinates[2]![randomNumber] != nil && coordinates[3]![randomNumber] != nil && coordinates[4]![randomNumber] != nil {
                    randomNumber = Int.random(in: Constants.availableFieldCoordinates)
                }
                coordinates[x]![randomNumber] = Int.random(in: 1...2) == 1 ? true : false
            }
        }
        return coordinates
    }
    
    
    init(gameMode : GameMode, gameType: GameType, gamesNames: [String]){
        self.gameMode = gameMode
        self.gameType = gameType
        self.gamesNames = gamesNames
    }
    
    func checkForWin() -> Bool{
        if player_2.destroyedShips == Constants.totalShipsOfPlayer {
            win = "You win the game!"
            return true
        }
        if player_1.destroyedShips == Constants.totalShipsOfPlayer {
            win = "\(player_2.name) wins!"
            return true
        }
        return false
    }
    
    func playerTurn(coordinate: Int, update: @escaping () -> Void) {
        hit = false
        shipDestroyed = false
        if currentOponent.usedCoordinates == nil {
            currentOponent.usedCoordinates = [Int]()
        }
        currentOponent.usedCoordinates!.append(coordinate)
        if let ships = oponentShips.ships {
            for ship in ships{
                if ship.coordinates.contains(coordinate){
                    hit = true
                    for shipCoordinate in ship.coordinates{
                        if coordinate == shipCoordinate {
                            ship.addUsedCoordinate(coordinate: coordinate)
                        }
                    }
                    if ship.coordinates == ship.usedCoordinates?.sorted(){
                        ship.isDestroyed = true
                        shipDestroyed = true
                    }
                }
            }
        }
        if hit == false{
            currentPlayerStatus = currentPlayerStatus == .player1 ? .player2 : .player1
        }
        update()
        if gameMode == .singleplayer && currentPlayerStatus == .player2{
            // wait 1 second, then make random turn
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.secondsToWaitForRandomToMakeTurn) { [weak self] in
                if let self = self {
                    var randomCoordinate = Int.random(in: Constants.availableFieldCoordinates)
                    var usedCoordinate = true
                    if self.currentOponent.usedCoordinates?.count == 0 ||  self.currentOponent.usedCoordinates == nil{
                        usedCoordinate = false
                    }
                    while(usedCoordinate){
                        if let usedCoordinates = self.currentOponent.usedCoordinates, usedCoordinates.contains(randomCoordinate) {
                            usedCoordinate = true
                        }
                        else {
                            usedCoordinate = false
                        }
                        if usedCoordinate == true {
                            randomCoordinate = Int.random(in: Constants.availableFieldCoordinates)
                        }
                    }
                    self.playerTurn(coordinate: randomCoordinate, update: update)
                }
            }
        }
        if shipDestroyed == true {
            currentOponent.destroyedShips += 1
        }
        if coordinate == -1 {
            if var usedCoordinates = player_2.usedCoordinates {
                if let index = usedCoordinates.firstIndex(of: coordinate) {
                    usedCoordinates.remove(at: index)
                }
            }
        }
    }
    
    func switchPlayers() {
        let ships = player_1.playerShips.ships
        let name = player_1.name
        let email = player_1.email
        player_1.playerShips.ships = player_2.playerShips.ships
        player_2.playerShips.ships = ships
        player_1.name = player_2.name
        player_2.name = name
        player_1.email = player_2.email
        player_2.email = email
    }
    
    func canPlayGame() -> Bool {
        if currentPlacingShips.shipsCount["1"]! == 0 && currentPlacingShips.shipsCount["2"]! == 0 && currentPlacingShips.shipsCount["3"]! == 0 && currentPlacingShips.shipsCount["4"]! == 0 {
            return true
        }
        return false
    }
    
    func canPlaceShips() -> Bool {
        if currentPlacingShips.shipsCount["1"]! > 0 || currentPlacingShips.shipsCount["2"]! > 0 || currentPlacingShips.shipsCount["3"]! > 0 || currentPlacingShips.shipsCount["4"]! > 0 {
            return true
        }
        return false
    }
    
    private struct Constants {
        
        static let availableFieldCoordinates = 5...104
        static let totalShipsOfPlayer = 10
        static let secondsToWaitForRandomToMakeTurn = 1.0
    }
}

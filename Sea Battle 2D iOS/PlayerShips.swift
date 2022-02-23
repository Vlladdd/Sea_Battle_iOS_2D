//
//  Ships.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 10/9/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import Foundation

// class that represents placing ships logic
class PlayerShips: Codable {
    
    // my system of coordinates use button tag as coordinate
    
    // this is lazy cuz when i try to encode it to Firebase for some reason it encodes as Array and not as Dictionary;
    // weird bug, but still there is should be enum for ship types instead of "1" etc
    lazy var shipsCount = ["1":4,"2":3,"3":2,"4":1]
    var ships: [Ship]?
    // coordinates on which player can`t place ships; _1 - when isRotateRight = true, _2 = when isRotateRight = false
    // 6 and 7 - coordinates for case where ship is placed in game field`s corner for calculate other locked coordinates correct
    var lockedCoordinates = ["1_1":[],"1_2":[],"2_1":[14,24,34,44,54,64,74,84,94,104],"2_2":[95,96,97,98,99,100,101,102,103,104],"3_1":[14,24,34,44,54,64,74,84,94,104,13,23,33,43,53,63,73,83,93,103],"3_2":[95,96,97,98,99,100,101,102,103,104,85,86,87,88,89,90,91,92,93,94],"4_1":[14,24,34,44,54,64,74,84,94,104,13,23,33,43,53,63,73,83,93,103,12,22,32,42,52,62,72,82,92,102],"4_2":[95,96,97,98,99,100,101,102,103,104,85,86,87,88,89,90,91,92,93,94,75,76,77,78,79,80,81,82,83,84],"6":[5,15,25,35,45,55,65,75,85,95],"7":[14,24,34,44,54,64,74,84,94]]
    
    
    private func createShip(rotation: Bool , coordinates: [Int] , type: Int , lockedCoordinates: [Int]){
        let ship = Ship(rotation: rotation, coordinates: coordinates, type: type , lockedCoordinates: lockedCoordinates , isDestroyed: false)
        if ships == nil {
            ships = [Ship]()
        }
        ships?.append(ship)
    }
    
    func removeShip(coordinate : Int){
        let index = ships?.firstIndex(where: { $0.coordinates.contains(coordinate)})
        if let index = index {
            removeLockedCoordinates(from: coordinate)
            if let ships = ships {
                shipsCount["\(ships[index].type)"]! += 1
            }
            ships?.remove(at: index)
        }
        // when we remove ship we also remove his locked coordinates
        // but sometimes this locked coordinates could be created by other ships
        // so its important to not remove that kind of locked coordinates
        if let ships = ships {
            for ship in ships {
                for coordinate in ship.lockedCoordinates {
                    createLockedCoordinates(from: coordinate)
                }
            }
        }
    }
    
    // when player create ship this func also creates coordinates on which other ships
    // cant be placed because of this ship ( other words because of need in distance between ships);
    // also creates lockedCoordinates for this ship
    func placingShip(coordinate: Int , shipType: Int,isRotateRight : Bool) -> Bool{
        // check if player can place ship at picked coordinate
        if shipType > 0 && shipType < 5 {
            if (isRotateRight && !lockedCoordinates["\(shipType)_1"]!.contains(coordinate)) || (!isRotateRight && !lockedCoordinates["\(shipType)_2"]!.contains(coordinate)){
                var shipX = 1
                var shipY = 1
                var cornerShipFactorLeft = 0
                var cornerShipFactorRight = 0
                var coordinates = [Int]()
                var lockedCoordinatesForShip = [Int]()
                if isRotateRight{
                    shipX = shipType
                    for coordinate in coordinate...coordinate+shipX-1{
                        coordinates.append(coordinate)
                        if lockedCoordinates["6"]!.contains(coordinate) {
                            cornerShipFactorLeft = 1
                        }
                        if lockedCoordinates["7"]!.contains(coordinate) {
                            cornerShipFactorRight = 1
                        }
                    }
                    lockedCoordinatesForShip = createCoordinatesForVerticalShip(startCoordinates: coordinates, cornerShipFactorLeft: cornerShipFactorLeft, cornerShipFactorRight: cornerShipFactorRight)
                }
                else{
                    shipY = shipType
                    for coordinate in coordinate...coordinate+shipX-1{
                        for i in stride(from: 0, through: 10 * shipY - 10, by: 10){
                            coordinates.append(coordinate+i)
                        }
                        if lockedCoordinates["6"]!.contains(coordinate) {
                            cornerShipFactorLeft = 1
                        }
                        if lockedCoordinates["7"]!.contains(coordinate) {
                            cornerShipFactorRight = 1
                        }
                    }
                    lockedCoordinatesForShip = createCoordinatesForHorizontalShip(startCoordinates: coordinates, cornerShipFactorLeft: cornerShipFactorLeft, cornerShipFactorRight: cornerShipFactorRight)
                }
                for coordinate in lockedCoordinatesForShip {
                    createLockedCoordinates(from: coordinate)
                }
                createShip(rotation: isRotateRight, coordinates: coordinates, type: shipType , lockedCoordinates: lockedCoordinatesForShip)
                shipsCount["\(shipType)"]! -= 1
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    func createCoordinatesForVerticalShip(startCoordinates: [Int], cornerShipFactorLeft: Int = 0, cornerShipFactorRight: Int = 0) -> [Int] {
        var lockedCoordinatesForShip = [Int]()
        for coordinate in (startCoordinates[0] - 11 + cornerShipFactorLeft)...(startCoordinates[0] - 10 + startCoordinates.count - cornerShipFactorRight) {
            lockedCoordinatesForShip.append(coordinate)
        }
        for coordinate in (startCoordinates[0] - 1 +  cornerShipFactorLeft)...(startCoordinates[0] + startCoordinates.count - cornerShipFactorRight) {
            lockedCoordinatesForShip.append(coordinate)
        }
        for coordinate in (startCoordinates[0] + 9 + cornerShipFactorLeft)...(startCoordinates[0] + 10 + startCoordinates.count - cornerShipFactorRight) {
            lockedCoordinatesForShip.append(coordinate)
        }
        return lockedCoordinatesForShip
    }
    
    func createCoordinatesForHorizontalShip(startCoordinates: [Int], cornerShipFactorLeft: Int = 0, cornerShipFactorRight: Int = 0) -> [Int] {
        var lockedCoordinatesForShip = [Int]()
        if cornerShipFactorLeft == 0 {
            for coordinate in stride(from: (startCoordinates[0] - 11) , through: ((startCoordinates[0] - 11) + 10 * startCoordinates.count + 10), by: 10) {
                lockedCoordinatesForShip.append(coordinate)
            }
        }
        for coordinate in stride(from: (startCoordinates[0] - 10), through: ((startCoordinates[0] - 10) + 10 * startCoordinates.count + 10), by: 10) {
            lockedCoordinatesForShip.append(coordinate)
        }
        if cornerShipFactorRight == 0 {
            for coordinate in stride(from: (startCoordinates[0] - 9), through: ((startCoordinates[0] - 9) + 10 * startCoordinates.count + 10), by: 10) {
                lockedCoordinatesForShip.append(coordinate)
            }
        }
        return lockedCoordinatesForShip
    }
    
    // when player place ship creates locked coordinates for all ships and ship types
    func createLockedCoordinates (from coordinate : Int) {
        for index1 in 1...4 {
            for index2 in 1...2 {
                lockedCoordinates["\(index1)_\(index2)"]!.append(coordinate)
            }
        }
        createLockedCoordinatesForShipType(from: coordinate, type: 2)
        createLockedCoordinatesForShipType(from: coordinate, type: 3)
        createLockedCoordinatesForShipType(from: coordinate, type: 4)
        // making all values unique
        for data in lockedCoordinates {
            var set = Set<Int>()
            for value in data.value {
                set.insert(value)
            }
            lockedCoordinates[data.key] = Array(set)
        }
    }
    
    func createLockedCoordinatesForShipType(from coordinate: Int, type: Int) {
        if type > 0 && type < 5 {
            for index in 0..<type {
                lockedCoordinates["\(type)_1"]!.append(coordinate - index)
                lockedCoordinates["\(type)_2"]!.append(coordinate - 10 * index)
            }
        }
    }
    
    func removeLockedCoordinatesForShipType(from coordinate: Int, type: Int) {
        if type > 0 && type < 5 {
            for index in 0..<type {
                if let arrayIndex = lockedCoordinates["\(type)_1"]!.firstIndex(of: coordinate - index) {
                    lockedCoordinates["\(type)_1"]!.remove(at: arrayIndex)
                }
                if let arrayIndex = lockedCoordinates["\(type)_2"]!.firstIndex(of: coordinate - 10 * index) {
                    lockedCoordinates["\(type)_2"]!.remove(at: arrayIndex)
                }
            }
        }
    }
    
    // when player remove ship removes locked coordinates for all ships and ship types
    func removeLockedCoordinates (from coordinate : Int) {
        for index1 in 1...4 {
            for index2 in 1...2 {
                if let ship = ships?.first(where: {$0.coordinates[0] == coordinate}) {
                    for coordinate in ship.lockedCoordinates {
                        if let indexOfElement = lockedCoordinates["\(index1)_\(index2)"]!.firstIndex(of: coordinate) {
                            lockedCoordinates["\(index1)_\(index2)"]!.remove(at: indexOfElement)
                        }
                        removeLockedCoordinatesForShipType(from: coordinate, type: 2)
                        removeLockedCoordinatesForShipType(from: coordinate, type: 3)
                        removeLockedCoordinatesForShipType(from: coordinate, type: 4)
                    }
                }
            }
        }
        // it`s important to not remove start locked coordinates
        lockedCoordinates["2_1"]! += [14,24,34,44,54,64,74,84,94,104]
        lockedCoordinates["2_2"]! += [95,96,97,98,99,100,101,102,103,104]
        lockedCoordinates["3_1"]! += [14,24,34,44,54,64,74,84,94,104,13,23,33,43,53,63,73,83,93,103]
        lockedCoordinates["3_2"]! += [95,96,97,98,99,100,101,102,103,104,85,86,87,88,89,90,91,92,93,94]
        lockedCoordinates["4_1"]! += [14,24,34,44,54,64,74,84,94,104,13,23,33,43,53,63,73,83,93,103,12,22,32,42,52,62,72,82,92,102]
        lockedCoordinates["4_2"]! += [95,96,97,98,99,100,101,102,103,104,85,86,87,88,89,90,91,92,93,94,75,76,77,78,79,80,81,82,83,84]
        // making all values unique
        for data in lockedCoordinates {
            var set = Set<Int>()
            for value in data.value {
                set.insert(value)
            }
            lockedCoordinates[data.key] = Array(set)
        }
    }
    
}

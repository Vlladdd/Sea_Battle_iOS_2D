//
//  Ships.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechiporenko on 10/9/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import Foundation

class PlayerShips {
    
    
    var shipsCount = ["1":4,"2":3,"3":2,"4":1]
    var ships = [Ship]()
    var allCoordinates = [Int]()
    var lockedCoordinates = ["1.1":[],"1.2":[],"2.1":[14,24,34,44,54,64,74,84,94,104],"2.2":[95,96,97,98,99,100,101,102,103,104],"3.1":[14,24,34,44,54,64,74,84,94,104,13,23,33,43,53,63,73,83,93,103],"3.2":[95,96,97,98,99,100,101,102,103,104,85,86,87,88,89,90,91,92,93,94],"4.1":[14,24,34,44,54,64,74,84,94,104,13,23,33,43,53,63,73,83,93,103,12,22,32,42,52,62,72,82,92,102],"4.2":[95,96,97,98,99,100,101,102,103,104,85,86,87,88,89,90,91,92,93,94,75,76,77,78,79,80,81,82,83,84],"5":[],"6":[5,15,25,35,45,55,65,75,85,95],"7":[14,24,34,44,54,64,74,84,94]]
    
    
    func createShip(rotation: Bool , coordinates: [Int] , type: Int , lockedCoordinates: [Int]){
        let ship = Ship(rotation: rotation, coordinates: coordinates, type: type , lockedCoordinates: lockedCoordinates , isDestroyed: false)
        ships.append(ship)
    }
    
    func addCoordinates(){
        for ship in ships {
            for value in ship.coordinates{
                allCoordinates.append(value)
            }
        }
    }
    
    func removeShip(coordinates : [Int]){
        ships.remove(at: ships.firstIndex(where: { $0.coordinates == coordinates })!)
    }
    
    func placingShip(sender: Int , ship: Int,in key:Int,isRotateRight : Bool) -> Bool{
        if (isRotateRight && !lockedCoordinates["\(key).1"]!.contains(sender)) || (!isRotateRight && !lockedCoordinates["\(key).2"]!.contains(sender)){
            var shipX = 1
            var shipY = 1
            var changer1 = 0
            var changer2 = 0
            var coordinates = [Int]()
            var lockedCoordinatesForShip = [Int]()
            if isRotateRight{
                shipX = ship
                for x in sender...sender+shipX-1{
                    coordinates.append(x)
                }
            }
            else{
                shipY = ship
                for x in sender...sender+shipX-1{
                    for i in stride(from: 0, through: 10*shipY-10, by: 10){
                        coordinates.append(x+i)
                    }
                }
            }
            for element in lockedCoordinates["6"]!{
                if coordinates.contains(element){
                    changer1 = 1
                }
            }
            for element in lockedCoordinates["7"]!{
                if coordinates.contains(element){
                    changer2 = -1
                }
            }
            for x in sender-1+changer1...sender+shipX+changer2{
                for i in stride(from: -10, through: 10*shipY, by: 10){
                    lockedCoordinates["5"]?.append(x+i)
                    lockedCoordinatesForShip.append(x+i)
                }
            }
            createShip(rotation: isRotateRight, coordinates: coordinates, type: ship , lockedCoordinates: lockedCoordinatesForShip)
            return true
        }
        else {
            return false
        }
    }
    
    func createLockedCoordinates (x : Int) {
        lockedCoordinates["1.1"]?.append(x)
        lockedCoordinates["1.2"]?.append(x)
        lockedCoordinates["2.1"]?.append(x)
        lockedCoordinates["3.1"]?.append(x)
        lockedCoordinates["4.1"]?.append(x)
        lockedCoordinates["2.2"]?.append(x)
        lockedCoordinates["3.2"]?.append(x)
        lockedCoordinates["4.2"]?.append(x)
        lockedCoordinates["2.1"]?.append(x-1)
        lockedCoordinates["2.2"]?.append(x-10)
        lockedCoordinates["3.1"]?.append(x-2)
        lockedCoordinates["4.1"]?.append(x-3)
        lockedCoordinates["3.2"]?.append(x-20)
        lockedCoordinates["4.2"]?.append(x-30)
    }
    
    func removeLockedCoordinates (x : Int) {
        lockedCoordinates["1.1"]!.remove(at: (lockedCoordinates["1.1"]!.firstIndex(of: x))!)
        lockedCoordinates["1.2"]!.remove(at: (lockedCoordinates["1.2"]!.firstIndex(of: x))!)
        lockedCoordinates["2.1"]!.remove(at: (lockedCoordinates["2.1"]!.firstIndex(of: x))!)
        lockedCoordinates["3.1"]!.remove(at: (lockedCoordinates["3.1"]!.firstIndex(of: x))!)
        lockedCoordinates["4.1"]!.remove(at: (lockedCoordinates["4.1"]!.firstIndex(of: x))!)
        lockedCoordinates["2.2"]!.remove(at: (lockedCoordinates["2.2"]!.firstIndex(of: x))!)
        lockedCoordinates["3.2"]!.remove(at: (lockedCoordinates["3.2"]!.firstIndex(of: x))!)
        lockedCoordinates["4.2"]!.remove(at: (lockedCoordinates["4.2"]!.firstIndex(of: x))!)
        lockedCoordinates["2.1"]!.remove(at: (lockedCoordinates["2.1"]!.firstIndex(of: x-1))!)
        lockedCoordinates["2.2"]!.remove(at: (lockedCoordinates["2.2"]!.firstIndex(of: x-10))!)
        lockedCoordinates["3.1"]!.remove(at: (lockedCoordinates["3.1"]!.firstIndex(of: x-2))!)
        lockedCoordinates["4.1"]!.remove(at: (lockedCoordinates["4.1"]!.firstIndex(of: x-3))!)
        lockedCoordinates["3.2"]!.remove(at: (lockedCoordinates["3.2"]!.firstIndex(of: x-20))!)
        lockedCoordinates["4.2"]!.remove(at: (lockedCoordinates["4.2"]!.firstIndex(of: x-30))!)
    }
    
    func deleteShips () {
        ships.removeAll()
        allCoordinates.removeAll()
        shipsCount = ["1":4,"2":3,"3":2,"4":1]
        lockedCoordinates = ["1.1":[],"1.2":[],"2.1":[14,24,34,44,54,64,74,84,94,104],"2.2":[95,96,97,98,99,100,101,102,103,104],"3.1":[14,24,34,44,54,64,74,84,94,104,13,23,33,43,53,63,73,83,93,103],"3.2":[95,96,97,98,99,100,101,102,103,104,85,86,87,88,89,90,91,92,93,94],"4.1":[14,24,34,44,54,64,74,84,94,104,13,23,33,43,53,63,73,83,93,103,12,22,32,42,52,62,72,82,92,102],"4.2":[95,96,97,98,99,100,101,102,103,104,85,86,87,88,89,90,91,92,93,94,75,76,77,78,79,80,81,82,83,84],"5":[]]
    }
}

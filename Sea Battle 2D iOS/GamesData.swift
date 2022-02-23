//
//  SeverConector.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 15.02.2022.
//  Copyright © 2022 Vlad Nechyporenko. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseDatabaseSwift

// class that represents game storage
class GamesData {
    
    private(set) var singlePlayerGamesNames : [String] = []
    private(set) var multiplayerGamesNames : [String] = []
    private(set) var multiplayerAvailableForJoinGamesNames : [String] = []
    private(set) var oneScreenGamesNames : [String] = []
    private(set) var games : [Game] = []
    
    var currentGame: Game?
    let currentDatabase = DatabaseName.firebase
    
    private var firebaseDatabase = Database.database().reference()
    
    enum DatabaseName {
        case mongoDB
        case firebase
    }
    
    
    //MARK: - Operations
    
    func save(game: Game) {
        switch currentDatabase {
        case .mongoDB:
            saveToMongoDB(game: game)
        case .firebase:
            saveToFirebase(game: game)
        }
    }
    
    func getGames(email: String) {
        switch currentDatabase {
        case .mongoDB:
            getGamesFromMongoDB(email: email)
        case .firebase:
            getGamesFromFirebase(email: email)
        }
    }
    
    func delete(game: Game) {
        switch currentDatabase {
        case .mongoDB:
            deleteFromMongoDB(game: game)
        case .firebase:
            deleteFromFirebase(game: game)
        }
    }
    
    func changeStatusOf(game: Game) {
        switch currentDatabase {
        case .mongoDB:
            changeStatusInMongoDBOf(game: game)
        case .firebase:
            changeStatusInFirebaseOf(game: game)
        }
    }
    
    //MARK: - MongoDB
    
    private func getGamesFromMongoDB(email: String) {
        serverTask(data: nil, url: URL(string: "http://localhost:3000/")!, method: "GET", someTask: {
            [weak self] data in
            if let self = self {
                do {
                    self.singlePlayerGamesNames = []
                    self.multiplayerGamesNames = []
                    self.oneScreenGamesNames = []
                    let gamesData = try JSONDecoder().decode([Game].self, from: data)
                    let games = gamesData
                    self.games = games
                    for game in games {
                        if game.gameMode == .singleplayer && game.player_1.email == email{
                            self.singlePlayerGamesNames.append(game.name)
                        }
                        if game.gameMode == .multiplayer{
                            self.multiplayerGamesNames.append(game.name)
                        }
                        if game.gameMode == .onescreen && game.player_1.email == email{
                            self.oneScreenGamesNames.append(game.name)
                        }
                    }
                    self.singlePlayerGamesNames.sort()
                    self.multiplayerGamesNames.sort()
                    self.oneScreenGamesNames.sort()
                }
                catch {
                    print("Couldn't parse json \(error)")
                }
            }
        })
    }
    
    private func saveToMongoDB(game: Game) {
        serverTask(data: game, url: URL(string: "http://localhost:3000/")!, method: "POST", someTask: nil)
    }
    
    private func deleteFromMongoDB(game: Game) {
        serverTask(data: game, url: URL(string: "http://localhost:3000/delete")!, method: "POST", someTask: nil)
    }
    
    private func changeStatusInMongoDBOf(game: Game) {
        serverTask(data: game, url: URL(string: "http://localhost:3000/edit")!, method: "POST", someTask: nil)
    }
    
    private func serverTask(data: Game?, url: URL, method: String, someTask: ((_ data: Data) -> Void)?) {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = method
        if let data = data {
            request.httpBody = try! data.encode()
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {
                      print("error", error ?? "Unknown error")
                      return
                  }
            
            guard (200 ... 299) ~= response.statusCode else {                    
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            if let someTask = someTask {
                someTask(data)
            }
            
        }
        
        task.resume()
    }
    
    //MARK: - Firebase
    
    private func getGamesFromFirebase(email: String) {
        let gamesRef = firebaseDatabase.child("games")
        gamesRef.observe(DataEventType.value, with: { [weak self] snapshot in
            if let self = self {
                guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                    return
                }
                self.games = []
                self.singlePlayerGamesNames = []
                self.multiplayerAvailableForJoinGamesNames = []
                self.multiplayerGamesNames = []
                self.oneScreenGamesNames = []
                for object in children {
                    guard let games = object.children.allObjects as? [DataSnapshot] else {
                        return
                    }
                    for game in games{
                        let gameValue = try! game.data(as: Game.self)
                        self.games.append(gameValue)
                        if gameValue.gameMode == .singleplayer && gameValue.player_1.email == email{
                            self.singlePlayerGamesNames.append(gameValue.name)
                        }
                        if gameValue.gameMode == .multiplayer{
                            self.multiplayerGamesNames.append(gameValue.name)
                        }
                        if gameValue.gameMode == .multiplayer && gameValue.gameType != .playing{
                            self.multiplayerAvailableForJoinGamesNames.append(gameValue.name)
                        }
                        if gameValue.gameMode == .onescreen && gameValue.player_1.email == email{
                            self.oneScreenGamesNames.append(gameValue.name)
                        }
                    }
                }
                self.singlePlayerGamesNames.sort()
                self.multiplayerGamesNames.sort()
                self.oneScreenGamesNames.sort()
            }
        })
    }
    
    private func saveToFirebase(game: Game) {
        try? firebaseDatabase.child("games").child(game.gameMode.rawValue).child(game.name).setValue(from: game)
        if game.gameType == .create && game.gameMode == .multiplayer {
            firebaseDatabase.child("games").child(game.gameMode.rawValue).child(game.name).onDisconnectRemoveValue()
        }
    }
    
    private func deleteFromFirebase(game: Game) {
        firebaseDatabase.child("games").child(game.gameMode.rawValue).child(game.name).removeValue()
    }
    
    private func changeStatusInFirebaseOf(game: Game) {
        firebaseDatabase.child("games").child(game.gameMode.rawValue).child(game.name).updateChildValues(["gameType": game.gameType.rawValue])
    }
}

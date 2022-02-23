//
//  MainMenuViewController.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 11/12/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseCore
import Firebase
import FirebaseAuth
import FirebaseDatabase


// VC that controls main menu
class MainMenuViewController: UIViewController{
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        adjustFonts()
        gamesData.getGames(email: email)
        if notificationCenter.checkIfNotificationsAvailable() {
            notificationCenter.allowNotifications()
        }
        notificationCenter.scheduleNotification(title: "Sea Battle", body: "Come play the game!", id: "MainMenu", schedule: .everyday)
        userName.text = name
    }
    
    //MARK: - Variables
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var listButtons: UIStackView!
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet var buttons: [UIButton]!
    
    private let notificationCenter = LocalNotifications()
    private let gamesData = GamesData()
    private var gameMode : String?
    private var gameType : String?
    private var gameName : String?
    private var startIndex = 0
    private var currentGamesNames : [String] = []
    private var pickedGame : Game?
    
    var email = GIDSignIn.sharedInstance.currentUser!.profile!.email
    var name = GIDSignIn.sharedInstance.currentUser!.profile!.name
    
    //MARK: - Local Functions
    
    private func adjustFonts() {
        for button in buttons {
            self.adjustFont(for: button, using: .medium)
        }
        self.adjustFont(for: signOutButton, using: .medium)
        self.adjustFont(for: previousButton, using: .medium)
        self.adjustFont(for: userName, using: .medium)
    }
    
    private func pageCreator ( gamesNames : [String] , gamesStartIndex : Int = 0) {
        if gamesNames.count > 2 {
            if gamesStartIndex + 2 <= gamesNames.count {
                var index = 0
                for i in gamesStartIndex..<gamesStartIndex + 2 {
                    buttons[index].setTitle(gamesNames[i], for: .normal)
                    buttons[index].isEnabled = true
                    buttons[index].isHidden = false
                    index += 1
                }
            }
            else {
                buttons[0].setTitle(gamesNames[gamesStartIndex], for: .normal)
                buttons[1].isEnabled = false
                buttons[1].alpha = 0
            }
        }
        else  {
            for i in 0..<gamesNames.count {
                buttons[i].setTitle(gamesNames[i], for: .normal)
            }
            for i in gamesNames.count..<2 {
                buttons[i].isEnabled = false
                buttons[i].alpha = 0
            }
        }
        listButtons.isUserInteractionEnabled = true
        listButtons.isHidden = false
        if startIndex+2 >= gamesNames.count {
            nextButton.isEnabled = false
        }
        else {
            nextButton.isEnabled = true
        }
        if startIndex != 0 {
            previousButton.isEnabled = true
        }
        else {
            previousButton.isEnabled = false
        }
    }
    
    //MARK: - Button Functions
    
    @IBAction func signOut(_ sender: UIButton) {
        GIDSignIn.sharedInstance.signOut()
        performSegue(withIdentifier: "Sign In", sender: nil)
    }
    
    @IBAction func menuButton(_ sender: UIButton) {
        gamesData.getGames(email: email)
        if gameMode != nil && gameType != nil && sender.currentTitle != "Back" && sender.currentTitle != "Previous" && sender.currentTitle != "Next"{
            gameName = sender.currentTitle
            for game in gamesData.games {
                if game.name == gameName && game.gameType != .playing {
                    self.pickedGame = game
                }
            }
            if let _ = pickedGame {
                if gameType! != "Join" {
                    performSegue(withIdentifier: gameType!, sender: nil)
                }
                else {
                    performSegue(withIdentifier: "Placing Ships", sender: nil)
                }
            }
            else {
                if gameMode! == "Multiplayer" && gameType! == "Join" {
                    self.gameBadStatusAlert()
                }
                gameMode = nil
                gameType = nil
                gameName = nil
                buttons[0].setTitle("SinglePlayer", for: .normal)
                buttons[1].setTitle("OneScreen", for: .normal)
                buttons[2].setTitle("Multiplayer", for: .normal)
                for button in buttons {
                    button.isEnabled = true
                    button.isHidden = false
                    button.alpha = 1
                }
                listButtons.isUserInteractionEnabled = false
                listButtons.isHidden = true
            }
        }
        if gameMode == nil {
            gameMode = sender.currentTitle
            switch gameMode {
            case "SinglePlayer" : currentGamesNames = gamesData.singlePlayerGamesNames
            case "Multiplayer" : currentGamesNames = gamesData.multiplayerAvailableForJoinGamesNames
            case "OneScreen" : currentGamesNames = gamesData.oneScreenGamesNames
            default : print("Wrong gamemode")
            }
            buttons[0].setTitle("Create", for: .normal)
            if gameMode != "Multiplayer" {
                buttons[1].setTitle("Load", for: .normal)
            }
            else {
                buttons[1].setTitle("Join", for: .normal)
            }
            buttons[2].setTitle("Back", for: .normal)
        }
        else {
            if sender.currentTitle != "Back" && gameType == nil{
                gameType = sender.currentTitle
            }
            if sender.currentTitle == "Back" {
                gameMode = nil
                gameType = nil
                gameName = nil
                buttons[0].setTitle("SinglePlayer", for: .normal)
                buttons[1].setTitle("OneScreen", for: .normal)
                buttons[2].setTitle("Multiplayer", for: .normal)
                for button in buttons {
                    button.isEnabled = true
                    button.alpha = 1
                }
                listButtons.isUserInteractionEnabled = false
                listButtons.isHidden = true
            }
            if sender.currentTitle == "Load"{
                pageCreator(gamesNames: currentGamesNames)
            }
            if sender.currentTitle == "Join" {
                pageCreator(gamesNames: currentGamesNames)
            }
            if sender.currentTitle == "Next"{
                startIndex += 2
                pageCreator(gamesNames: currentGamesNames , gamesStartIndex: startIndex)
            }
            if sender.currentTitle == "Previous"{
                startIndex -= 2
                pageCreator(gamesNames: currentGamesNames , gamesStartIndex: startIndex)
            }
        }
    }
    
    //MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gameMode = gameMode, let gameType = gameType {
            self.firebaseAction(itemID: "gameTypeChoose", itemName: "User choose to \(gameType) game with gamemode \(gameMode)")
        }
        var gameMode = Game.GameMode.singleplayer
        switch self.gameMode {
        case "SinglePlayer" : gameMode = .singleplayer
        case "OneScreen" : gameMode = .onescreen
        case "Multiplayer" : gameMode = .multiplayer
        default: gameMode = .none
        }
        if gameType == "Create" {
            if let PlacingVC = segue.destination as? PlacingShipsViewController{
                if gameMode == .multiplayer {
                    currentGamesNames = gamesData.multiplayerGamesNames
                }
                let game = Game(gameMode : gameMode, gameType: .create, gamesNames: currentGamesNames)
                game.player_1.email = email
                game.player_1.name = name
                PlacingVC.game = game
            }
        }
        if gameType == "Load" {
            if let GameVC = segue.destination as? GameViewController{
                GameVC.game = pickedGame!
            }
        }
        if gameType == "Join"{
            if let PlacingVC = segue.destination as? PlacingShipsViewController{
                PlacingVC.game = Game(gameMode : gameMode, gameType: .join, gamesNames: currentGamesNames)
                PlacingVC.game.name = gameName!
                PlacingVC.game.player_1.email = pickedGame!.player_1.email
                PlacingVC.game.player_1.name = pickedGame!.player_1.name
                PlacingVC.game.player_2.email = email
                PlacingVC.game.player_2.name = name
                PlacingVC.badGameName = false
                pickedGame!.gameType = .playing
                gamesData.changeStatusOf(game: pickedGame!)
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if gameMode != nil && gameType == "Create"  && gameName == nil {
            return true
        }
        if gameMode != nil && gameType == "Load"  && gameName != nil {
            return true
        }
        if gameMode != nil && gameType == "Join"  && gameName != nil {
            return true
        }
        return false
    }
    
}



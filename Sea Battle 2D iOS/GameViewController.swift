//
//  GameViewController.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 10/23/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import UIKit
import Starscream
import Firebase
import FirebaseDatabase

// VC that controls game view
class GameViewController: UIViewController , WebSocketDelegate{
    
    //MARK: - Websockets
    
    private var socket: Starscream.WebSocket!
    
    private func starscream() {
        
        self.socket = WebSocket(url: URL(string: "ws://localhost:1337/")!, protocols: ["chat"])
        
        self.socket.delegate = self
        socket.connect()
        
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("Connected")
        socket.write(string: game.gameType.rawValue)
        
        if game.gameType == .join {
            let data = ["email" : game.player_1.email, "gameName" : game.name, "coordinate" : 1] as [String: Any]
            socket.write(data: try! JSONSerialization.data(withJSONObject: data))
        }
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        
    }
    
    // players trade turns with each other
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        
        // i can make a class that represents a message and make him codable but i leave it like this for now
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {[weak self] _ in
            if let self = self {
                let data1 = ["email" : self.game.player_1.email, "gameName" : self.game.name, "coordinate" : 500] as [String: Any]
                let data2 = ["email" : self.game.player_2.email, "gameName" : self.game.name, "coordinate" : 500] as [String: Any]
                self.socket.write(data: try! JSONSerialization.data(withJSONObject: data1))
                self.socket.write(data: try! JSONSerialization.data(withJSONObject: data2))
            }
        })
        
        guard let data = text.data(using: .utf16),
            let jsonData = try? JSONSerialization.jsonObject(with: data),
            let jsonDict = jsonData as? [String: Any],
            let messageType = jsonDict["type"] as? String else {
                return
        }
        
        var player1TurnTag = 0
        var player2TurnTag = 0
        
        if messageType == "message"{
            let messageData = jsonDict["data"] as! [String: Any]
            let player1Turn = messageData["player1Turn"] as? [String: Any]
            let player2Turn = messageData["player2Turn"] as? [String: Any]
            
            if let player1Turn = player1Turn, let coordinate = player1Turn["coordinate"] as? Int, player1Turn["email"] as? String == game.player_1.email, player1Turn["gameName"] as? String == game.name {
                player1TurnTag = coordinate
            }
            
            if let player2Turn = player2Turn, let coordinate = player2Turn["coordinate"] as? Int, player2Turn["email"] as? String == game.player_1.email, player2Turn["gameName"] as? String == game.name {
                player2TurnTag = coordinate
            }
        }
        
        if player1TurnTag != 0 && game.gameType == .join && player1TurnTag != 500 && player1TurnTag != 1{
            playerTurn(tag: player1TurnTag)
        }
        if player2TurnTag != 0 && game.gameType == .create && player1TurnTag != 500 && player2TurnTag != 1{
            playerTurn(tag: player2TurnTag)
        }
        
        if (player1TurnTag == 500 || player2TurnTag == 500) && !seguePerformed {
            seguePerformed = true
            self.gameBadStatusAlert()
        }
        
        // ensures, that both players are ready
        if player2TurnTag == 1 && game.gameType == .create {
            self.hideSpinner(nil)
        }

        
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
    
    //MARK: - Variables
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var player1: UILabel!
    @IBOutlet weak var player2: UILabel!
    @IBOutlet weak var gameButton: UIButton!
    @IBOutlet weak var winnerLabel: UILabel!
    @IBOutlet weak var stackViewButtons: UIStackView!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet var player1FieldButtons: [UIButton]!
    @IBOutlet var player2FieldButtons: [UIButton]!
    @IBOutlet var fieldNames: [UILabel]!

    private var player1shipsCollection = [1:[UIImageView](),2:[UIImageView](),3:[UIImageView](),4:[UIImageView]()]
    private var player2shipsCollection = [1:[UIImageView](),2:[UIImageView](),3:[UIImageView](),4:[UIImageView]()]
    private lazy var player1ships = game.player_1.playerShips.ships
    private lazy var player2ships = game.player_2.playerShips.ships
    private lazy var gamemode = game.gameMode
    private let gamesData = GamesData()
    // timer is made for case if server is crash or player is afk
    private var timer: Timer?
    // checks if segue was already performed( or about to perform) so it will not trigger again
    // cuz sometimes you can get extra message from websocket server which will again trigger segue
    private var seguePerformed = false
    
    var game : Game!
    
    //MARK: - View functions
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        adjustFonts()
    }
    
    // changes UI depending on game mode
    override func viewDidAppear(_ animated: Bool) {
        checkForGameMode(gamemode : gamemode)
        player1.text = game.player_1.name
        if gamemode == .singleplayer {
            player2.text = "Random Generator"
            // if player saved game when Random Generator was about to make turn
            if game.currentPlayerStatus == .player2 {
                game.currentPlayerStatus = .player1
                playerTurn(tag: -1)
            }
        }
        if gamemode == .onescreen {
            player2.text = "Player2"
        }
        if game.gameType == .create && game.gameMode == .multiplayer {
            self.showSpinner(nil)
        }
        if gamemode == .multiplayer {
            timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {[weak self] _ in
                if let self = self {
                    let data1 = ["email" : self.game.player_1.email, "gameName" : self.game.name, "coordinate" : 500] as [String: Any]
                    let data2 = ["email" : self.game.player_2.email, "gameName" : self.game.name, "coordinate" : 500] as [String: Any]
                    self.socket.write(data: try! JSONSerialization.data(withJSONObject: data1))
                    self.socket.write(data: try! JSONSerialization.data(withJSONObject: data2))
                }
            })
            saveButton.isHidden = true
            deleteButton.isHidden = true
            player2.text = game.player_2.name
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.gamesData?.currentGame = game
            starscream()
            appDelegate.socket = socket
        }
        if let player1ships = player1ships, let player2ships = player2ships {
            placingShips(ships : player1ships , buttons: player1FieldButtons , hiden : true , player : 1)
            placingShips(ships : player2ships , buttons: player2FieldButtons , hiden : true , player : 2)
            updateFields()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if gamemode == .multiplayer {
            socket.disconnect()
        }
    }
    
    //MARK: - Local Functions
    
    private func adjustFonts() {
        self.adjustFont(for: saveButton, using: .big)
        self.adjustFont(for: menuButton, using: .big)
        self.adjustFont(for: gameButton, using: .medium)
        self.adjustFont(for: player1, using: .big)
        self.adjustFont(for: player2, using: .big)
        self.adjustFont(for: winnerLabel, using: .medium)
        self.adjustFont(for: deleteButton, using: .big)
    }

    // places ships on game fields
    private func placingShips(ships : [Ship] , buttons : [UIButton] , hiden : Bool , player : Int){
        for ship in ships{
            for button in buttons{
                if ship.coordinates[0] == button.tag{
                    let imageName = "ship_\(ship.type)"
                    let image = UIImage(named: imageName)
                    let imageView = UIImageView(image: image!)
                    if(ship.isRotateRight){
                        imageView.frame.size.height = button.frame.size.height
                        imageView.frame.size.width = button.frame.size.width*CGFloat(ship.type)
                    }
                    else{
                        imageView.transform = imageView.transform.rotated(by: CGFloat.pi/2)
                        imageView.frame.size.height = button.frame.size.height*CGFloat(ship.type)
                        imageView.frame.size.width = button.frame.size.width
                    }
                    imageView.frame.origin = button.convert(button.bounds.origin, to: self.view)
                    imageView.contentMode = .scaleAspectFit
                    imageView.isHidden = hiden
                    imageView.tag = button.tag
                    if ship.isDestroyed {
                        imageView.isHidden = false
                    }
                    if player == 1 {
                        player1shipsCollection[ship.type]?.append(imageView)
                    }
                    if player == 2 {
                        player2shipsCollection[ship.type]?.append(imageView)
                    }
                    view.addSubview(imageView)
                }
            }
        }
    }
    
    // makes turn of player
    private func playerTurn(tag : Int){
        self.firebaseAction(itemID: "playerTurn", itemName: "\(game.currentPlayerStatus) made turn with coordinate \(tag)")
        game.playerTurn(coordinate: tag) {[weak self] in
            self?.updateFields()
        }
        checkForEndGame()
    }
    
    // checks if someone win the game and update UI if yes ( other words if destroyedShips of player = 10)
    private func checkForEndGame() {
        if game.checkForWin() {
            timer?.invalidate()
            for button in player1FieldButtons {
                button.removeFromSuperview()
            }
            for button in player2FieldButtons {
                button.removeFromSuperview()
            }
            for shipType in player1shipsCollection {
                for ship in shipType.value {
                    ship.removeFromSuperview()
                }
            }
            for shipType in player2shipsCollection {
                for ship in shipType.value {
                    ship.removeFromSuperview()
                }
            }
            for name in fieldNames {
                name.removeFromSuperview()
            }
            player1.removeFromSuperview()
            player2.removeFromSuperview()
            menuButton.removeFromSuperview()
            saveButton.removeFromSuperview()
            deleteButton.removeFromSuperview()
            winnerLabel.text = game.win
            winnerLabel.layer.zPosition = .greatestFiniteMagnitude
            gameButton.layer.zPosition = .greatestFiniteMagnitude
            stackViewButtons.isUserInteractionEnabled = true
            winnerLabel.isHidden = false
            gameButton.isHidden = false
            gamesData.delete(game: game)
        }
    }
    
    // updates UI at the start of the game
    private func checkForGameMode(gamemode : Game.GameMode){
        if gamemode == .singleplayer {
            for button in player1FieldButtons {
                button.isEnabled = false
            }
        }
        if gamemode == .multiplayer && game.gameType == .join{
            player1.backgroundColor = UIColor.clear
            player2.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            game.currentPlayerStatus = .player2
            for button in player1FieldButtons {
                button.isEnabled = false
            }
        }
        if gamemode == .multiplayer && game.gameType == .create{
            player1.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            player2.backgroundColor = UIColor.clear
            for button in player1FieldButtons {
                button.isEnabled = false
            }
        }
        if gamemode != .multiplayer {
            player1.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        }
    }
    
    // updates UI after player made turn
    private func updateButtons(buttons: [UIButton], usedCoordinates: [Int]?, ships: [Ship]) {
        if let usedCoordinates = usedCoordinates {
            for button in buttons{
                if usedCoordinates.contains(button.tag){
                    button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                    button.isEnabled = false
                }
                for ship in ships{
                    if ship.coordinates.contains(button.tag) && usedCoordinates.contains(button.tag){
                        button.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                        button.isEnabled = false
                    }
                }
            }
        }
    }
    
    // updates UI after player made turn
    private func updateShips(ships: [Ship], shipsCollection: [Int : [UIImageView]], buttons: [UIButton]) {
        for ship in ships{
            if ship.isDestroyed {
                for image in shipsCollection[ship.type]!{
                    if ship.coordinates[0] == image.tag{
                        image.isHidden = false
                    }
                    for button in buttons {
                        for coordinate in ship.lockedCoordinates{
                            if button.tag == coordinate{
                                button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                                button.isEnabled = false
                            }
                        }
                    }
                    for button in buttons {
                        for coordinate in ship.coordinates{
                            if button.tag == coordinate{
                                button.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // updates UI after player made turn
    private func updateFields() {
        switchPlayerViews()
        updateButtons(buttons: player2FieldButtons, usedCoordinates: game.player_2.usedCoordinates, ships: player2ships!)
        updateButtons(buttons: player1FieldButtons, usedCoordinates: game.player_1.usedCoordinates, ships: player1ships!)
        updateShips(ships: player2ships!, shipsCollection: player2shipsCollection, buttons: player2FieldButtons)
        updateShips(ships: player1ships!, shipsCollection: player1shipsCollection, buttons: player1FieldButtons)
    }
    
    // updates UI after player made turn
    private func switchPlayerViews() {
        if game.hit == false{
            if gamemode == .singleplayer || gamemode == .multiplayer{
                if game.currentPlayerStatus == .player2 {
                    for button in player2FieldButtons {
                        button.isEnabled = false
                    }
                }
                else {
                    for button in player2FieldButtons {
                        button.isEnabled = true
                    }
                }
            }
            if gamemode == .onescreen {
                if game.currentPlayerStatus == .player1 {
                    for button in player1FieldButtons {
                        button.isEnabled = false
                    }
                    for button in player2FieldButtons {
                        button.isEnabled = true
                    }
                }
                else {
                    for button in player2FieldButtons {
                        button.isEnabled = false
                    }
                    for button in player1FieldButtons {
                        button.isEnabled = true
                    }
                }
            }
            if game.currentPlayerStatus == .player1 {
                player1.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                player2.backgroundColor = UIColor.clear
            }
            else {
                player1.backgroundColor = UIColor.clear
                player2.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            }
        }
    }
    
    //MARK: - Button functions
    
    
    // makes turn of player
    @IBAction func playerTurn(_ sender: UIButton) {
        playerTurn(tag: sender.tag)
        if gamemode == .multiplayer {
            if game.gameType == .create {
                let data = ["email" : game.player_1.email, "gameName" : game.name, "coordinate" : sender.tag] as [String: Any]
                socket.write(data: try! JSONSerialization.data(withJSONObject: data))
            }
            if game.gameType == .join {
                let data = ["email" : game.player_2.email, "gameName" : game.name, "coordinate" : sender.tag] as [String: Any]
                socket.write(data: try! JSONSerialization.data(withJSONObject: data))
            }
        }
    }
    
    // saves game to database
    @IBAction func save(_ sender: UIButton) {
        self.firebaseAction(itemID: "saveGame", itemName: "User saved game with gamename \(game.name)")
        gamesData.save(game: game)
    }
    
    // deletes game from database
    @IBAction func deleteGame(_ sender: UIButton) {
        self.firebaseAction(itemID: "deletGame", itemName: "User deleted game with gamename \(game.name)")
        gamesData.delete(game: game)
    }
    
    //MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.firebaseAction(itemID: "startMenu", itemName: "User went to start menu")
        seguePerformed = true
        
        if gamemode == .multiplayer {
            if !game.checkForWin() {
                let data1 = ["email" : game.player_1.email, "gameName" : game.name, "coordinate" : 500] as [String: Any]
                let data2 = ["email" : game.player_2.email, "gameName" : game.name, "coordinate" : 500] as [String: Any]
                socket.write(data: try! JSONSerialization.data(withJSONObject: data1))
                socket.write(data: try! JSONSerialization.data(withJSONObject: data2))
            }
            gamesData.delete(game: game)
        }
    }
    
}

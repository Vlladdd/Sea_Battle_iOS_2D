//
//  ViewController.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 10/1/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import UIKit
import Firebase
import Starscream


// VC that controls placing ships view
class PlacingShipsViewController: UIViewController, WebSocketDelegate {
    
    //MARK: Websockets
    
    private var socket: Starscream.WebSocket!
    
    private func starscream() {
        
        socket = WebSocket(url: URL(string: "ws://localhost:1337/")!, protocols: ["chat"])
        socket.delegate = self
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
    
    // used to let players trade ships with each other and notify user if creator left the game
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        
        // i can make a class that represents a message and make him codable but i leave it like this for now
        
        guard let data = text.data(using: .utf16),
              let jsonData = try? JSONSerialization.jsonObject(with: data),
              let jsonDict = jsonData as? [String: Any],
              let messageType = jsonDict["type"] as? String else {
                  return
              }
        
        if messageType == "message"{
            do {
                let totalData = try JSONSerialization.jsonObject(with: data, options: [])
                if let data = totalData as? [String : Any] {
                    if let playerData = data["data"] as? [String: Any] {
                        if let gameData = playerData["player1Turn"] as? [String: Any]{
                            if let email = gameData["email"] as? String, email == game.player_1.email, gameData["gameName"] as? String == game.name, game.player_1.playerShips.ships?.count != 10{
                                if let shipData = gameData["player1Ships"] as? [[String: Any]]{
                                    game.player_1.playerShips.ships = [Ship]()
                                    for ship in shipData {
                                        let rotation = ship["isRotateRight"] as! Bool
                                        let isDestroyed = ship["isDestroyed"] as! Bool
                                        let type = ship["type"] as! Int
                                        let coordinates = ship["coordinates"] as! [Int]
                                        let lockedCoordinates = ship["lockedCoordinates"] as! [Int]
                                        let usedCoordinates = ship["usedCoordinates"] as! [Int]
                                        game.player_1.playerShips.ships!.append(Ship(rotation: rotation, coordinates: coordinates, type: type, lockedCoordinates: lockedCoordinates , isDestroyed: isDestroyed, usedCoordinates: usedCoordinates))
                                    }
                                }
                                if let name = gameData["name"] as? String {
                                    game.player_1.name = name
                                }
                                game.player_1.email = email
                            }
                        }
                        if let gameData = playerData["player2Turn"] as? [String: Any]{
                            if let email = gameData["email"] as? String, email == game.player_1.email, gameData["gameName"] as? String == game.name, game.player_2.playerShips.ships?.count != 10{
                                if let shipData = gameData["player2Ships"] as? [[String: Any]]{
                                    game.player_2.playerShips.ships = [Ship]()
                                    for ship in shipData {
                                        let rotation = ship["isRotateRight"] as! Bool
                                        let isDestroyed = ship["isDestroyed"] as! Bool
                                        let type = ship["type"] as! Int
                                        let coordinates = ship["coordinates"] as! [Int]
                                        let lockedCoordinates = ship["lockedCoordinates"] as! [Int]
                                        let usedCoordinates = ship["usedCoordinates"] as! [Int]
                                        game.player_2.playerShips.ships!.append(Ship(rotation: rotation, coordinates: coordinates, type: type, lockedCoordinates: lockedCoordinates , isDestroyed: isDestroyed, usedCoordinates: usedCoordinates))
                                    }
                                }
                                if let name = gameData["name"] as? String {
                                    game.player_2.name = name
                                }
                                game.player_2.email = email
                            }
                        }
                    }
                }
            }
            catch {
                print("Couldn't parse json \(error)")
            }
            
            if game.player_1.playerShips.ships?.count == 10 && game.player_2.playerShips.ships?.count == 10 && !sequePerformed && shipsPlaced {
                sequePerformed = true
                let playerShips = game.player_1.playerShips.ships!.map({ ["isDestroyed": $0.isDestroyed , "isRotateRight": $0.isRotateRight,"coordinates" : $0.coordinates , "usedCoordinates" : $0.usedCoordinates ?? [0] , "lockedCoordinates" : $0.lockedCoordinates , "type" : $0.type] })
                let data = ["email" : game.player_1.email, "name" : game.player_1.name, "player1Ships" : playerShips, "gameName": game.name] as [String: Any]
                socket.write(data: try! JSONSerialization.data(withJSONObject: data))
                performSegue(withIdentifier: "Game", sender: nil)
            }
        }
        
        if let messageData = jsonDict["data"] as? [String: Any] {
            var playerTurnTag = 0
            let player1Turn = messageData["player1Turn"] as? [String: Any]
            let player2Turn = messageData["player2Turn"] as? [String: Any]
            
            if let game = game, let player1Turn = player1Turn, let coordinate = player1Turn["coordinate"] as? Int, player1Turn["email"] as? String == game.player_1.email, player1Turn["gameName"] as? String == game.name {
                playerTurnTag = coordinate
            }
            
            if let game = game, let player2Turn = player2Turn, let coordinate = player2Turn["coordinate"] as? Int, player2Turn["email"] as? String == game.player_1.email, player2Turn["gameName"] as? String == game.name {
                playerTurnTag = coordinate
            }
            
            if playerTurnTag == 500 && !sequePerformed{
                self.gameBadStatusAlert()
            }
            
            if playerTurnTag == 1 {
                gameNameLabel.text = "Waiting for player 2 to be ready ..."
            }
        }

        
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
    
    //MARK: View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustFonts()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        gamesData.getGames(email: game.player_1.email)
        if game.gameMode == .multiplayer {
            starscream()
        }
        if game.gameType == .join {
            gameName.isEnabled = false
            gameName.alpha = 0
            gameNameLabel.alpha = 0
        }
    }
    
    //MARK: Variables
    
    // my system of coordinates use button tag as coordinate
    
    @IBOutlet weak var gameName: UITextField!
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var gameNameLabel: UILabel!
    @IBOutlet weak var pickedShip: UIImageView!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet var fieldButtons: [UIButton]!
    // this buttons contains specific tags so when we choose them placing ship
    // func will do nothing and instead pickedShip will be changed
    @IBOutlet var shipButtonsColection: [UIButton]!
    @IBOutlet var actionButtons: [UIButton]!
    
    private let gamesData = GamesData()
    // timer is made for case if server is crash or player is afk
    private var timer: Timer?
    private var shipsPlaced = false
    // checks if segue was already performed( or about to perform) so it will not trigger again
    // cuz sometimes you can get extra message from websocket server which will again trigger segue
    private var sequePerformed = false
    private var shipToRemoveTag = 0
    private var isRotateRight = true
    private var currentShipType = 0
    private var shipsCollection = [1:[UIImageView](),2:[UIImageView](),3:[UIImageView](),4:[UIImageView]()]
    
    var badGameName = true
    var game : Game!
    
    
    //MARK: - Local Functions
    
    private func adjustFonts() {
        for button in actionButtons {
            self.adjustFont(for: button, using: .verySmall)
        }
        self.adjustFont(for: gameNameLabel, using: .veryBig)
        self.adjustFont(for: gameName, using: .veryBig)
        for ship in shipButtonsColection {
            ship.contentVerticalAlignment = .fill
            ship.contentHorizontalAlignment = .fill
        }
    }
    
    private func availableFieldsInAxis(key: Int) {
        if currentShipType > 0 && currentShipType < 5 {
            for button in fieldButtons{
                if game.currentPlacingShips.lockedCoordinates["\(currentShipType)_\(key)"]!.contains(button.tag){
                    button.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
                }
                else {
                    button.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                }
                button.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                button.borderWidth = 1
            }
        }
    }
    
    // available fields to place picked ship type
    private func availableFields(){
        let playerShips = game.currentPlacingShips
        if currentShipType > 0 && currentShipType < 5 {
            if isRotateRight{
                availableFieldsInAxis(key: 1)
            }
            else {
                availableFieldsInAxis(key: 2)
            }
            if playerShips.shipsCount["\(currentShipType)"]! == 0 {
                for button in fieldButtons{
                    button.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
                }
            }
        }
        else {
            for button in fieldButtons{
                button.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
                button.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                button.borderWidth = 1
            }
        }
        // highlight all ships of picked type
        if currentShipType != 0{
            if let ships = playerShips.ships {
                for button in fieldButtons {
                    for ship in ships{
                        if ship.type == currentShipType && shipToRemoveTag == 0{
                            if ship.coordinates.contains(button.tag){
                                button.borderColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
                                button.borderWidth = 3
                            }
                        }
                        else if shipToRemoveTag != 0{
                            if ship.coordinates.contains(shipToRemoveTag){
                                for coordinate in ship.coordinates{
                                    if(button.tag == coordinate){
                                        button.borderColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
                                        button.borderWidth = 3
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        canPlayGame()
    }
    
    // check if game can be start ( other words current player ships was placed and also gameName was set)
    private func canPlayGame() {
        if game.canPlayGame() && badGameName == false{
            startGameButton.isEnabled = true
        }
        else {
            startGameButton.isEnabled = false
        }
    }
    
    // placing ship of player
    // if coordinate is empty - try to place ship, else - change pickedShip
    private func placingShip(sender: UIButton , shipType: Int,isRotateRight : Bool, ships : PlayerShips){
        var isShipPlaced = false
        if shipType > 0 && shipType < 5, ships.shipsCount["\(shipType)"]! > 0{
            isShipPlaced = ships.placingShip(coordinate: sender.tag, shipType: shipType, isRotateRight: isRotateRight)
        }
        if (isShipPlaced == true){
            if game.gameMode != .singleplayer || (game.gameMode == .singleplayer && game.currentPlacingPlayer == .player1){
                let imageName = "ship_\(shipType)"
                let image = UIImage(named: imageName)
                let imageView = UIImageView(image: image!)
                imageView.tag = sender.tag
                if(isRotateRight){
                    imageView.frame.size.height = sender.frame.size.height
                    imageView.frame.size.width = sender.frame.size.width*CGFloat(shipType)
                }
                else{
                    imageView.transform = imageView.transform.rotated(by: CGFloat.pi/2)
                    imageView.frame.size.height = sender.frame.size.height*CGFloat(shipType)
                    imageView.frame.size.width = sender.frame.size.width
                }
                imageView.frame.origin = sender.convert(sender.bounds.origin, to: self.view)
                imageView.contentMode = .scaleAspectFit
                view.addSubview(imageView)
                shipToRemoveTag = imageView.tag
                shipsCollection[shipType]?.append(imageView)
            }
        }
        else{
            if let unwrapedShips = ships.ships {
                for ship in unwrapedShips{
                    if ship.coordinates.contains(sender.tag){
                        shipToRemoveTag = ship.coordinates[0]
                        currentShipType = ship.type
                        pickedShip.image = UIImage(named: "ship_\(ship.type)")
                    }
                }
            }
        }
        availableFields()
    }
    
    private func removingShip(shipToRemove:UIImageView){
        let playerShips = game.currentPlacingShips
        playerShips.removeShip(coordinate: shipToRemove.tag)
    }
    
    // delete one ship or delete ships of picked type or delete all ships
    private func deleteShips() {
        var shipToRemove = UIImageView()
        if shipToRemoveTag != 0, currentShipType > 0 && currentShipType < 5 {
            for image in shipsCollection[currentShipType]!{
                if(image.tag == shipToRemoveTag){
                    if let index = shipsCollection[currentShipType]!.firstIndex(of: image) {
                        shipToRemove = shipsCollection[currentShipType]!.remove(at: index)
                        image.removeFromSuperview()
                        removingShip(shipToRemove: shipToRemove)
                    }
                }
            }
        }
        else if currentShipType > 0 && currentShipType < 5{
            for image in shipsCollection[currentShipType]!{
                if let index = shipsCollection[currentShipType]!.firstIndex(of: image) {
                    shipToRemove = shipsCollection[currentShipType]!.remove(at: index)
                    image.removeFromSuperview()
                    removingShip(shipToRemove: shipToRemove)
                }
            }
        }
        else {
            for (key,value) in shipsCollection{
                for image in value{
                    shipToRemove = shipsCollection[key]!.remove(at: shipsCollection[key]!.firstIndex(of: image)!)
                    image.removeFromSuperview()
                    currentShipType = key
                    removingShip(shipToRemove: shipToRemove)
                }
            }
        }
        shipToRemoveTag = 0
        currentShipType = 0
        pickedShip.image = nil
        availableFields()
    }
    
    
    //MARK: - Button Functions
    
    @IBAction func clearShips(_ sender: UIButton) {
        self.firebaseAction(itemID: "removeShips", itemName: "User remove ship(s)")
        self.showSpinner({[weak self] in
            self?.deleteShips()
        })
        self.hideSpinner(nil)
    }
    
    // placing ships randomly
    @IBAction func random(_ sender: UIButton) {
        self.firebaseAction(itemID: "randomShips", itemName: "User decided to place ships randomly")
        var coordinates = game.randomCoordinates()
        self.showSpinner({ [weak self] in
            if let self = self {
                // if user already place all ships and want to place them random again
                if !self.game.canPlaceShips() {
                    self.shipToRemoveTag = 0
                    self.currentShipType = 0
                    self.deleteShips()
                }
                while self.game.canPlaceShips(){
                    for button in self.fieldButtons{
                        for shipType in 1...4{
                            if let coordinates = coordinates[shipType]![button.tag]{
                                self.placingShip(sender: button, shipType: shipType, isRotateRight: coordinates, ships : self.game.currentPlacingShips)
                            }
                        }
                    }
                    coordinates = self.game.randomCoordinates()
                    self.shipToRemoveTag = 0
                    self.currentShipType = 0
                    self.pickedShip.image = nil
                    self.availableFields()
                }
            }
        })
        self.hideSpinner({ [weak self] in
            if let self = self {
                if self.game.player_1.playerShips.ships?.count == 10 && self.game.player_2.playerShips.ships?.count == 10 && self.game.gameMode == .singleplayer {
                    self.performSegue(withIdentifier: "Game", sender: nil)
                }
            }
        })
    }
    
    
    // choose ship to place
    @IBAction func shipToChoose(_ sender: UIButton) {
        pickedShip.image = sender.image(for: .normal)
        currentShipType = sender.tag % 300
        shipToRemoveTag = 0
        availableFields()
    }
    
    // rotate ship (can`t rotate ship which is already placed)
    @IBAction func rotateButton(_ sender: UIButton) {
        if isRotateRight{
            pickedShip.transform = pickedShip.transform.rotated(by: CGFloat.pi/2)
            isRotateRight = false
        }
        else{
            pickedShip.transform = pickedShip.transform.rotated(by: -(CGFloat.pi/2))
            isRotateRight = true
        }
        availableFields()
    }
    
    // game field button
    @IBAction func button(_ sender: UIButton) {
        placingShip(sender: sender, shipType: currentShipType, isRotateRight: isRotateRight, ships : game.currentPlacingShips)
    }
    
    // check whether the game with picked name is already exist
    @IBAction func gameName(_ sender: UITextField) {
        gameName.resignFirstResponder()
        if game.gamesNames?.firstIndex(of: sender.text!) == nil && sender.text!.count > 0 && sender.text!.count < 11{
            game.name = sender.text!
            badGameName = false
            sender.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        }
        else {
            let alertController = UIAlertController(title: nil, message: "Name should have more then 0 characters and less then 11 \n or this name is already taken", preferredStyle: .alert)
            alertController.addAction(.init(title: "Ok", style: .default))
            self.present(alertController, animated: true, completion: nil)
            sender.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
            badGameName = true
        }
        canPlayGame()
    }
    
    //MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.firebaseAction(itemID: "gameCreated", itemName: "User created game with gamemode: \(game.gameMode) and gamename: \(gameName.text!)")
        if let GameVC = segue.destination as? GameViewController{
            if game.gameMode == .multiplayer {
                if game.gameType == .join{
                    timer?.invalidate()
                    game.switchPlayers()
                }
            }
            GameVC.game = game
        }
        if let _ = segue.destination as? MainMenuViewController {
            if game.gameMode == .multiplayer {
                if game.name != "" {
                    gamesData.delete(game: game)
                }
                let data = ["email" : self.game.player_1.email, "gameName" : self.game.name, "coordinate" : 500] as [String: Any]
                socket.write(data: try! JSONSerialization.data(withJSONObject: data))
            }
        }
    }
    
    // check if game can be start in picked game mode
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let ident = identifier {
            if ident == "New Game" {
                return true
            }
            if ident == "Game" {
                startGameButton.isEnabled = false
                if game.player_1.playerShips.ships?.count == 10 && game.player_2.playerShips.ships?.count == 10 {
                    return true
                }
                if game.gameMode == .onescreen {
                    if game.currentPlacingPlayer == .player1 {
                        for ship in shipsCollection {
                            for value in ship.value {
                                value.removeFromSuperview()
                            }
                        }
                        shipsCollection = [1:[UIImageView](),2:[UIImageView](),3:[UIImageView](),4:[UIImageView]()]
                    }
                    if game.currentPlacingPlayer == .player2 {
                        return true
                    }
                    game.player_1.ready = true
                    for button in fieldButtons {
                        button.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                    }
                    return false
                }
                if game.gameMode == .singleplayer {
                    game.player_1.ready = true
                    random(UIButton())
                    return false
                }
                if game.gameMode == .multiplayer && !shipsPlaced{
                    let playerShips = game.player_1.playerShips.ships!.map({ ["isDestroyed": $0.isDestroyed , "isRotateRight": $0.isRotateRight,"coordinates" : $0.coordinates , "usedCoordinates" : $0.usedCoordinates ?? [0] , "lockedCoordinates" : $0.lockedCoordinates , "type" : $0.type] })
                    if game.gameType == .create {
                        let data = ["email" : game.player_1.email, "name" : game.player_1.name, "player1Ships" : playerShips, "gameName" : game.name] as [String: Any]
                        gamesData.save(game: game)
                        socket.write(data: try! JSONSerialization.data(withJSONObject: data))
                        game.player_1.ready = true
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.gamesData?.currentGame = game
                        appDelegate.socket = socket
                        gameName.isHidden = true
                        gameNameLabel.text = "Waiting for oponent..."
                        for button in actionButtons {
                            button.isEnabled = false
                        }
                        backButton.isEnabled = true
                    }
                    else if game.gameType == .join {
                        let data = ["email" : game.player_2.email, "name" : game.player_2.name, "player2Ships" : playerShips, "gameName" : game.name] as [String: Any]
                        game.player_2.playerShips = game.player_1.playerShips
                        game.player_1.playerShips = PlayerShips()
                        game.player_2.ready = true
                        socket.write(data: try! JSONSerialization.data(withJSONObject: data))
                        self.showSpinner(nil)
                        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: {[weak self] _ in
                            self?.hideSpinner(nil)
                            self?.gameBadStatusAlert()
                        })
                    }
                    shipsPlaced = true
                    return false
                }
            }
        }
        return false
    }
    
}

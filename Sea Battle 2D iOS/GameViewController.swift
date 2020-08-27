//
//  GameViewController.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechiporenko on 10/23/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import UIKit
import Starscream

class GameViewController: UIViewController , WebSocketDelegate{
    var socket: Starscream.WebSocket!
    func websocketDidConnect(socket: WebSocketClient) {
        print("Connected")
        socket.write(string: type!)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        // 1
        guard let data = text.data(using: .utf16),
            let jsonData = try? JSONSerialization.jsonObject(with: data),
            let jsonDict = jsonData as? [String: Any],
            let messageType = jsonDict["type"] as? String else {
                return
        }
        
        print(jsonDict)
        
        // 2
        if messageType == "message"{
            let messageData = jsonDict["data"] as! [String: Any]
            let player1Turn = messageData["player1Turn"] as! String
            let player2Turn = messageData["player2Turn"] as! String
            
            if let number = Int(player1Turn.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                    turn1 = number
            }
            
            if let number = Int(player2Turn.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                    turn2 = number
            }
        }
        print(turn1)
        print(turn2)
        player = 2
        if turn1 != 0 && type == "Join"{
            playerTurn(tag: turn1)
        }
        if turn2 != 0 && type == "Create"{
            playerTurn(tag: turn2)
        }

        
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
    
    var type: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        checkForGameMode(gamemode : gamemode!)
        placingButtons()
        if gamemode == 2 {
        starscream()
        }
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        placingShips(ships : player1ships! , buttons: player1FieldButtons , hiden : true , player : 1)
        placingShips(ships : player2ships! , buttons: player2FieldButtons , hiden : true , player : 2)
    }
    
    override func viewDidLayoutSubviews() {
        player1.font = player1.font.withSize(self.view.frame.height / 17)
        player2.font = player1.font.withSize(self.view.frame.height / 17)
        winnerLabel.font = winnerLabel.font.withSize(self.view.frame.height / 10)
        gameButton.titleLabel?.font = .systemFont(ofSize: self.view.frame.height / 10)
    }
    
    var turn1 = 0
    var turn2 = 0
    @IBOutlet weak var stackViewButtons: UIStackView!
    
    @IBAction func save(_ sender: UIButton) {
        let requestBody = ["name" : game!.name! , "gamemode" : game!.gamemode! , "player1UsedCoordinates" : game!.player_1!.usedCoordinates, "player2UsedCoordinates" : game!.player_2!.usedCoordinates, "player1Ships" : game!.player_1!.playerShips!.ships.map({ ["isDestroyed": $0.isDestroyed , "isRotateRight": $0.isRotateRight,"coordinates" : $0.coordinates , "usedCoordinates" : $0.usedCoordinates , "lockedCoordinates" : $0.lockedCoordinates , "type" : $0.type] }), "player2Ships" : game!.player_2!.playerShips!.ships.map({ ["isDestroyed": $0.isDestroyed , "isRotateRight": $0.isRotateRight,"coordinates" : $0.coordinates , "usedCoordinates" : $0.usedCoordinates , "lockedCoordinates" : $0.lockedCoordinates , "type" : $0.type] })] as [String : Any]
        server(player1Dictionary: requestBody)
    }
    
    @IBOutlet weak var player1: UILabel!
    @IBOutlet var player1FieldButtons: [UIButton]!
    @IBOutlet weak var player2: UILabel!
    
    @IBOutlet var player2FieldButtons: [UIButton]!
    
    @IBOutlet weak var gameButton: UIButton!
    @IBOutlet weak var winnerLabel: UILabel!
    var game : Game?
    
    lazy var player1ships = game?.player_1?.playerShips?.ships
    lazy var player2ships = game?.player_2?.playerShips?.ships
    
    var usedCoordinatesForPC = [200]
    
    var player_1_Hiden = true
    var player_2_Hiden = true
    
    lazy var gamemode = game?.gamemode

    func placingShips(ships : [Ship] , buttons : [UIButton] , hiden : Bool , player : Int){
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
                if ship.isDestroyed {
                    for coordinate in ship.lockedCoordinates {
                        if coordinate == button.tag {
                            button.isEnabled = false
                            button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                        }
                    }
                    for coordinate in ship.coordinates {
                        if coordinate == button.tag {
                            button.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                            button.isEnabled = false
                        }
                    }
                }
            }
        }
    }
    
    func starscream() {
           // let url = URL(string: "ws://localhost:8181/echo")!
            //let request = URLRequest(url: url)
            self.socket = WebSocket(url: URL(string: "ws://localhost:1337/")!, protocols: ["chat"])
            
            
            self.socket.delegate = self
            socket.connect()
           // print(socket.isConnected)
    //        let message = ["Name" : 33]
    //        let jsonEncoder = JSONEncoder()
    //
    //        do {
    //            let jsonData = try jsonEncoder.encode(message)
    //            self.socket.write(data: jsonData)
    //        } catch let error {
    //            print("error: \(error)")
    //        }
        }
    
    func placingButtons() {
        for coordinate in game!.player_1!.usedCoordinates {
            for button in player2FieldButtons {
                if button.tag == coordinate {
                    button.isEnabled = false
                    button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                }
            }
        }
        for coordinate in game!.player_2!.usedCoordinates {
            for button in player1FieldButtons {
                if button.tag == coordinate {
                    button.isEnabled = false
                    button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                }
            }
        }
        if game?.gamemode == 0 {
            usedCoordinatesForPC = game!.player_2!.usedCoordinates
        }
    }
    
    
    func checkForGameMode(gamemode : Int){
        if gamemode == 0 {
            player_1_Hiden = false
        }
        for button in player1FieldButtons {
            button.isEnabled = false
        }
        if gamemode == 2 && type == "Join"{
            player1.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
            player2.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            for button in player2FieldButtons {
                button.isEnabled = false
            }
        }
        if gamemode == 2 && type == "Create"{
            player1.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            player2.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        }
        if gamemode != 2 {
            player1.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        }
    }
    var player = 1
    var player1shipsCollection = [1:[UIImageView](),2:[UIImageView](),3:[UIImageView](),4:[UIImageView]()]
    var player2shipsCollection = [1:[UIImageView](),2:[UIImageView](),3:[UIImageView](),4:[UIImageView]()]
    
    
    @IBAction func playerTurn(_ sender: UIButton) {
        if gamemode == 2{
            player = 1
        }
        playerTurn(tag: sender.tag)
        if gamemode == 2 {
        socket.write(string: String(sender.tag))
        }
    }
    
    func playerTurn(tag : Int ){
        var hit = false
        var shipDestroyed = false
        if player == 1 {
            game?.player_1?.usedCoordinates.append(tag)
            for button in player2FieldButtons{
                if button.tag == tag{
                    button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                    button.isEnabled = false
                }
            }
            for i in 0..<player2ships!.count{
                if player2ships![i].coordinates.contains(tag){
                    for coordinate in player2ships![i].coordinates{
                        if coordinate == tag {
                            player2ships![i].addUsedCoordinate(coordinate: coordinate)
                            for button in player2FieldButtons{
                                if button.tag == coordinate{
                                    button.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                                    button.isEnabled = false
                                    hit = true
                                }
                            }
                        }
                    }
                    if player2ships![i].coordinates == player2ships![i].usedCoordinates.sorted(){
                        game?.player_2?.playerShips?.ships[i].isDestroyed = true
                        shipDestroyed = true
                        for image in player2shipsCollection[player2ships![i].type]!{
                            if player2ships![i].coordinates[0] == image.tag{
                                image.isHidden = false
                            }
                            for button in player2FieldButtons {
                                for coordinate in player2ships![i].lockedCoordinates{
                                    if button.tag == coordinate{
                                        button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                                        button.isEnabled = false
                                    }
                                }
                            }
                            for button in player2FieldButtons {
                                for coordinate in player2ships![i].coordinates{
                                    if button.tag == coordinate{
                                        button.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if hit == false && gamemode == 0{
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `2.0` to the desired number of seconds.
                    var randomCoordinate = Int.random(in: 5...114)
                    var usedCoordinate = true
                    while(usedCoordinate){
                        for coordinate in self.usedCoordinatesForPC {
                            if coordinate != randomCoordinate {
                                usedCoordinate = false
                            }
                            else {
                                usedCoordinate = true
                            }
                        }
                        if usedCoordinate == true {
                            randomCoordinate = Int.random(in: 5...114)
                        }
                    }
                    self.playerTurn(tag: randomCoordinate)
                }
            }
            if hit == false{
                if gamemode != 2 {
                    for button in player2FieldButtons {
                        button.isEnabled = false
                    }
                    for button in player1FieldButtons {
                        if !(game?.player_2?.usedCoordinates.contains(button.tag))!{
                            button.isEnabled = true
                        }
                    }
                }
                if gamemode == 2 {
                    for button in player2FieldButtons {
                        button.isEnabled = false
                    }
                }
                player1.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
                player2.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            }
            if shipDestroyed == true {
                game?.player_2?.destroyedShips += 1
            }
        }
        if player == 2 {
            game?.player_2?.usedCoordinates.append(tag)
            for button in player1FieldButtons {
                if button.tag == tag {
                    button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                    button.isEnabled = false
                }
            }
            for i in 0..<player1ships!.count{
                if player1ships![i].coordinates.contains(tag){
                    for coordinate in player1ships![i].coordinates{
                        if coordinate == tag {
                            player1ships![i].addUsedCoordinate(coordinate: coordinate)
                            for button in player1FieldButtons{
                                if button.tag == coordinate{
                                    button.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                                    button.isEnabled = false
                                    hit = true
                                    if gamemode == 0 {
                                        button.borderColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
                                        button.borderWidth = 3
                                    }
                                }
                            }
                        }
                    }
                    if player1ships![i].coordinates == player1ships![i].usedCoordinates.sorted(){
                        game?.player_1?.playerShips?.ships[i].isDestroyed = true
                        shipDestroyed = true
                        for image in player1shipsCollection[player1ships![i].type]!{
                            if player1ships![i].coordinates[0] == image.tag{
                                image.isHidden = false
                            }
                            for button in player1FieldButtons {
                                for coordinate in player1ships![i].lockedCoordinates{
                                    if button.tag == coordinate{
                                        button.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
                                        button.isEnabled = false
                                    }
                                }
                            }
                            for button in player1FieldButtons {
                                for coordinate in player1ships![i].coordinates{
                                    if button.tag == coordinate{
                                        button.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                                        if gamemode == 0 {
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
            if hit == true && gamemode == 0{
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `2.0` to the desired number of seconds.
                    var randomCoordinate = Int.random(in: 5...114)
                    var usedCoordinate = true
                    while(usedCoordinate){
                        for coordinate in self.usedCoordinatesForPC {
                            if coordinate != randomCoordinate {
                                usedCoordinate = false
                            }
                            else {
                                usedCoordinate = true
                            }
                        }
                        if usedCoordinate == true {
                            randomCoordinate = Int.random(in: 5...114)
                        }
                    }
                    self.playerTurn(tag: randomCoordinate)
                }
            }
            if hit == false{
                if gamemode != 2 {
                    for button in player2FieldButtons {
                        if !(game?.player_1?.usedCoordinates.contains(button.tag))!{
                            button.isEnabled = true
                        }
                    }
                    for button in player1FieldButtons {
                        button.isEnabled = false
                    }
                }
                if gamemode == 2 {
                    for button in player2FieldButtons {
                        if !(game?.player_1?.usedCoordinates.contains(button.tag))!{
                            button.isEnabled = true
                        }
                    }
                }
                player2.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
                player1.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            }
            if shipDestroyed == true {
                game?.player_1?.destroyedShips += 1
            }
        }
        if hit == false && gamemode != 2{
            player = player == 1 ? 2 : 1
        }
        if (game?.checkForWin())! {
            for button in player1FieldButtons {
                button.isEnabled = false
            }
            for button in player2FieldButtons {
                button.isEnabled = false
            }
            winnerLabel.text = game?.win
            winnerLabel.layer.zPosition = .greatestFiniteMagnitude
            gameButton.layer.zPosition = .greatestFiniteMagnitude
            stackViewButtons.isUserInteractionEnabled = true
            winnerLabel.isHidden = false
            gameButton.isHidden = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        game = nil
    }
    
    func server (player1Dictionary: [String : Any]) {
        let url = URL(string: "http://localhost:3000/")!
        var request = URLRequest(url: url)
       // request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: player1Dictionary)
        
        

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data,
                let response = response as? HTTPURLResponse,
                error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
            }

            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }

           // let responseString = String(data: data, encoding: .utf8)
            //print("responseString = \(String(describing: responseString))")
        }

        task.resume()
    }
    
}


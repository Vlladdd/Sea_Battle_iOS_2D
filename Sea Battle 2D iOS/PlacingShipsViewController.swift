//
//  ViewController.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechiporenko on 10/1/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import UIKit
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectWebSockets
import Realm
import RealmSwift





class PlacingShipsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       // resize()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        if type == "Join" {
            gameName.isEnabled = false
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        gameName.resignFirstResponder()
    }
    
    
    @IBOutlet weak var nextStageButton: UIButton!
    @IBAction func clearShips(_ sender: UIButton) {
        var shipToRemove = UIImageView()
        var playerShips : PlayerShips?
        if currentPlayer == 1{
            playerShips = player_1_Ships
        }
        if currentPlayer == 2{
            playerShips = player_2_Ships
        }
        if shipToRemoveTag != 0 {
            for image in shipsCollection[currentShip]!{
                if(image.tag == shipToRemoveTag){
                    shipToRemove = shipsCollection[currentShip]!.remove(at: shipsCollection[currentShip]!.firstIndex(of: image)!)
                    image.removeFromSuperview()
                    removingShip(shipToRemove: shipToRemove)
                    playerShips!.shipsCount["\(currentShip)"]! += 1
                }
            }
        }
        else if currentShip != 0{
            for image in shipsCollection[currentShip]!{
                shipToRemove = shipsCollection[currentShip]!.remove(at: shipsCollection[currentShip]!.firstIndex(of: image)!)
                image.removeFromSuperview()
                removingShip(shipToRemove: shipToRemove)
                playerShips!.shipsCount["\(currentShip)"]! += 1
            }
        }
        else {
            for (key,value) in shipsCollection{
                for image in value{
                    shipToRemove = shipsCollection[key]!.remove(at: shipsCollection[key]!.firstIndex(of: image)!)
                    image.removeFromSuperview()
                    currentShip = key
                    removingShip(shipToRemove: shipToRemove)
                    playerShips!.shipsCount["\(currentShip)"]! += 1
                }
            }
        }
        shipToRemoveTag = 0
        currentShip = 0
        rotateShip.image = nil
        availableFields()
    }
    @IBAction func random(_ sender: UIButton) {
        if currentPlayer == 1{
            random(ships : player_1_Ships)
        }
        if currentPlayer == 2{
            random(ships : player_2_Ships)
        }
    }
    
    
    var game : Game?
    
    func random(ships : PlayerShips){
        while ships.shipsCount["1"]! > 0 || ships.shipsCount["2"]! > 0 || ships.shipsCount["3"]! > 0 || ships.shipsCount["4"]! > 0{
            var numbers = [1:[Int](),2:[Int](),3:[Int](),4:[Int]()]
            for x in 1...4{
                for _ in 0...4-x{
                    numbers[x]!.append(Int.random(in: 5...114))
                }
            }
            for button in fieldButtons{
                let rotation = Int.random(in: 1...2) == 1 ? true : false
                for x in 1...4{
                    if numbers[x]!.contains(button.tag){
                        placingShip(sender: button, ship: x, in: x, isRotateRight: rotation, button_key: 300+x,ships : ships)
                    }
                }
            }
            shipToRemoveTag = 0
            currentShip = 0
            rotateShip.image = nil
            availableFields()
        }
    }
    var player_1_Ships = PlayerShips()
    var player_2_Ships = PlayerShips()
    
    var shipToRemoveTag = 0
    
    var isRotateRight = true
    var currentShip = 0
    
    @IBOutlet weak var rotateShip: UIImageView!
    
    
    @IBOutlet var fieldButtons: [UIButton]!
    
    
    @IBAction func shipToChoose(_ sender: UIButton) {
        rotateShip.image = sender.image(for: .normal)
        currentShip = sender.tag % 300
        shipToRemoveTag = 0
        availableFields()
    }
    
    @IBOutlet var buttonsColection: [UIButton]!
    
    var currentPlayer = 1
    
    var shipsCollection = [1:[UIImageView](),2:[UIImageView](),3:[UIImageView](),4:[UIImageView]()]
    
    
    var type: String?
    
    lazy var gamemode = game?.gamemode
    
    
    @IBAction func rotateButton(_ sender: UIButton) {
        if isRotateRight{
            rotateShip.transform = rotateShip.transform.rotated(by: CGFloat.pi/2)
            isRotateRight = false
        }
        else{
            rotateShip.transform = rotateShip.transform.rotated(by: -(CGFloat.pi/2))
            isRotateRight = true
        }
        availableFields()
    }
    
    @IBAction func button(_ sender: UIButton) {
        if currentPlayer == 1{
            placingShip(sender: sender, ship: currentShip, in: currentShip, isRotateRight: isRotateRight, button_key: 300+currentShip, ships : player_1_Ships)
        }
        if currentPlayer == 2{
            placingShip(sender: sender, ship: currentShip, in: currentShip, isRotateRight: isRotateRight, button_key: 300+currentShip, ships : player_2_Ships)
        }
    }
    
    func availableFields(){
        var playerShips : PlayerShips?
        if currentPlayer == 1{
            playerShips = player_1_Ships
        }
        if currentPlayer == 2{
            playerShips = player_2_Ships
        }
        if currentShip != 0 {
            if isRotateRight{
                for button in fieldButtons{
                    if playerShips!.lockedCoordinates["\(currentShip).1"]!.contains(button.tag){
                        button.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
                    }
                    else {
                        button.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                    }
                    button.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                    button.borderWidth = 1
                }
            }
            else {
                for button in fieldButtons{
                    if playerShips!.lockedCoordinates["\(currentShip).2"]!.contains(button.tag){
                        button.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
                    }
                    else {
                        button.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                    }
                    button.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                    button.borderWidth = 1
                }
            }
            if playerShips!.shipsCount["\(currentShip)"]! == 0 {
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
        if currentShip != 0{
            for button in fieldButtons {
                for ship in playerShips!.ships{
                    if ship.type == currentShip && shipToRemoveTag == 0{
                        if ship.coordinates.contains(button.tag){
                            button.borderColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
                            button.borderWidth = 3
                        }
                    }
                    else if shipToRemoveTag != 0{
                        for ship in playerShips!.ships{
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
        if playerShips?.shipsCount["1"] == 0 && playerShips?.shipsCount["2"] == 0 && playerShips?.shipsCount["3"] == 0 && playerShips?.shipsCount["4"] == 0 && badName == false{
            nextStageButton.isEnabled = true
        }
        else {
            nextStageButton.isEnabled = false
        }
    }
    

    
    
    func placingShip(sender: UIButton , ship: Int,in key_1:Int,isRotateRight : Bool,button_key key:Int, ships : PlayerShips){
        var isShipPlaced = false
        if ship != 0 , ships.shipsCount["\(ship)"]! > 0{
            isShipPlaced = ships.placingShip(sender: sender.tag, ship: ship, in: key_1, isRotateRight: isRotateRight)
        }
        if (isShipPlaced == true){
            ships.shipsCount["\(ship)"]! -= 1
            if gamemode != 0 || (gamemode == 0 && currentPlayer == 1){
            let imageName = "ship_\(ship)"
            let image = UIImage(named: imageName)
            let imageView = UIImageView(image: image!)
            imageView.tag = sender.tag
            if(isRotateRight){
                imageView.frame.size.height = sender.frame.size.height
                imageView.frame.size.width = sender.frame.size.width*CGFloat(ship)
            }
            else{
                imageView.transform = imageView.transform.rotated(by: CGFloat.pi/2)
                imageView.frame.size.height = sender.frame.size.height*CGFloat(ship)
                imageView.frame.size.width = sender.frame.size.width
            }
            imageView.frame.origin = sender.convert(sender.bounds.origin, to: self.view)
            imageView.contentMode = .scaleAspectFit
            view.addSubview(imageView)
            shipToRemoveTag = imageView.tag
            shipsCollection[ship]?.append(imageView)
            }
            var button1 = sender
            for coordinate in ships.lockedCoordinates["5"]!{
                if let button = self.view.viewWithTag(coordinate) as? UIButton {
                    if (abs((button1.frame.origin.x - button.frame.origin.x)) < 82) && (abs((button1.frame.origin.y - button.frame.origin.y)) < 10){
                        button1 = button
                        ships.createLockedCoordinates(x: ships.lockedCoordinates["5"]!.remove(at: ships.lockedCoordinates["5"]!.firstIndex(of: coordinate)!))
                    }
                    else{
                        ships.lockedCoordinates["5"]!.remove(at: ships.lockedCoordinates["5"]!.firstIndex(of: coordinate)!)                    }
                }
            }
        }
        else{
            for ship in ships.ships{
                if ship.coordinates.contains(sender.tag){
                    shipToRemoveTag = ship.coordinates[0]
                    currentShip = ship.type
                    rotateShip.image = UIImage(named: "ship_\(ship.type)")
                }
            }
        }
        availableFields()
    }
//    func resize(){
//        var x = 1
//        print(fieldButtons[1].frame.size.width)
//        print(fieldButtons[1].frame.size.height)
//        for button in buttonsColection{
//            button.widthAnchor.constraint(equalToConstant: fieldButtons[1].bounds.size.width * CGFloat(x)).isActive = true
//            button.heightAnchor.constraint(equalToConstant: fieldButtons[1].bounds.size.height).isActive = true
//            x += 1
//        }
//    }
    var badName = true
    @IBAction func gameName(_ sender: UITextField) {
        print(game!.gamesNames)
        if game?.gamesNames.firstIndex(of: sender.text!) == nil{
            game?.name = sender.text
            badName = false
            sender.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        }
        else {
            sender.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
            badName = true
        }
        availableFields()
    }
    @IBOutlet weak var gameName: UITextField!
    
    func removingShip(shipToRemove:UIImageView){
        var playerShips : PlayerShips?
        if currentPlayer == 1{
            playerShips = player_1_Ships
        }
        if currentPlayer == 2{
            playerShips = player_2_Ships
        }
        var shipX = 1
        var shipY = 1
        var button1 = self.view.viewWithTag(shipToRemove.tag) as? UIButton
        for ship in playerShips! .ships{
            if ship.coordinates.contains(shipToRemove.tag){
                isRotateRight = ship.isRotateRight
                playerShips!.removeShip(coordinates: ship.coordinates)
            }
        }
        if(isRotateRight){
            shipX = currentShip
        }
        else{
            shipY = currentShip
        }
        for x in shipToRemove.tag-1...shipToRemove.tag+shipX{
            for i in stride(from: -10, through: 10*shipY, by: 10){
                if let button = self.view.viewWithTag(x+i) as? UIButton {
                    if (abs((button1!.frame.origin.x - button.frame.origin.x)) < 82) && (abs((button1!.frame.origin.y - button.frame.origin.y)) < 10){
                        button1 = button
                        playerShips!.removeLockedCoordinates(x: x+i)
                    }
                }
            }
        }
        isRotateRight = true
    }
    
    var t = false
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let GameVC = segue.destination as? GameViewController{
            var t: [Ship] = []
            if type == "Join"{
                t = game!.player_1!.playerShips!.ships
                game!.player_1!.playerShips!.ships = game!.player_2!.playerShips!.ships
                game!.player_2!.playerShips!.ships = t
            }
            GameVC.game = game
            GameVC.type = type
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let ident = identifier {
            if ident == "Game" {
                nextStageButton.isEnabled = false
                if gamemode == 1 {
                    if currentPlayer == 1 {
                        game?.player_1?.playerShips? = player_1_Ships
                        for ship in shipsCollection {
                            for value in ship.value {
                                value.removeFromSuperview()
                            }
                        }
                        shipsCollection = [1:[UIImageView](),2:[UIImageView](),3:[UIImageView](),4:[UIImageView]()]
                    }
                    if currentPlayer == 2 {
                        game?.player_2?.playerShips = player_2_Ships
                        return true
                    }
                    currentPlayer = 2
                    for button in fieldButtons {
                        button.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                    }
                    return false
                }
                if gamemode == 0 {
                    game?.player_1?.playerShips = player_1_Ships
                    currentPlayer = 2
                    random(ships : player_2_Ships)
                    game?.player_2?.playerShips = player_2_Ships
                    return true
                }
                if gamemode == 2 {
                    //game?.player_1?.playerShips = player_1_Ships
                   // print(player_1_Ships.ships)
                    let player1Dictionary = player_1_Ships.ships.map({ ["isDestroyed": $0.isDestroyed , "isRotateRight": $0.isRotateRight,"coordinates" : $0.coordinates , "usedCoordinates" : $0.usedCoordinates , "lockedCoordinates" : $0.lockedCoordinates , "type" : $0.type] })
                    //print(player1Dictionary)
                    if type == "Create" {
                        let game = ["name" : self.game!.name! , "gamemode" : self.game!.gamemode! , "player1Ships" : player1Dictionary] as [String : Any]
                        server(player1Dictionary: game)
                    }
                    else if type == "Join" {
                        let ships = ["player2Ready" : true ,  "name" : self.game!.name! , "player2Ships" : player1Dictionary] as [String : Any]
                        edit(player1Dictionary: ships)
                    }
                    while t == false {
                        check()
                        sleep(1)
                    }
                    sleep(3)
                    answer()
                    sleep(1)
                    return true
                    //game?.player_1?.playerShips?.ships = answer()
                }
            }
        }
        return true
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

            //let responseString = String(data: data, encoding: .utf8)
            //print("responseString = \(String(describing: responseString))")
        }

        task.resume()
    }
    
    func edit (player1Dictionary: [String : Any]) {
        let url = URL(string: "http://localhost:3000/edit")!
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

            //let responseString = String(data: data, encoding: .utf8)
            //print("responseString = \(String(describing: responseString))")
        }

        task.resume()
    }
    
    func answer () {
            let url = URL(string: "http://localhost:3000/")!
            var request = URLRequest(url: url)
    //        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
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
                
               
              //  let responseString = String(data: data, encoding: .utf8)
                
                // Convert your response string to data or if you've data then pass it directly
              //  let jsonData = responseString?.data(using: .utf8)

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let array = json as? [[String : Any]] {
                        // print(json)
                        for k in array {
                            if let a = k["gamemode"] as? Int  {
                                if a == 2{
                                    if k["name"] as! String == self.game!.name! {
                                        self.game = Game(game: k)
                                        print(self.game!)
                                    }
                                }
                            }
                        }
                        
                    }
                }
                catch {
                    print("Couldn't parse json \(error)")
                }
                

                
                
                
        
                //print("responseString = \(responseString!)")
            }
            
            task.resume()
           // print(games)
        }
        
    
    func check () {
            let url = URL(string: "http://localhost:3000/check")!
            var request = URLRequest(url: url)
    //        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"
            let params = [ "name" : game!.name! , "player2Ready" : true] as [String : Any]
            request.httpBody = try! JSONSerialization.data(withJSONObject: params)
        
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
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
                
               
                let responseString = String(data: data, encoding: .utf8)
                
                if responseString == "true" {
                    self.t = true
                }
                
                // Convert your response string to data or if you've data then pass it directly
                //  let jsonData = responseString?.data(using: .utf8)
               
//                do {
//                    let json = try JSONSerialization.jsonObject(with: data, options: [])
//                    if let array = json as? Bool{
//                        t = array
//                    }
//
//
//                }
//                catch {
//                    print("Couldn't parse json \(error)")
//                }
                

                
                
                
        
               // print("responseString = \(responseString!)")
            }
            
            task.resume()
        }
    
}

extension NSLayoutConstraint {
    
    override open var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)" //you may print whatever you want here
    }
}


extension UIButton {
    @IBInspectable var adjustFontSizeToWidth: Bool {
        get {
            return self.titleLabel!.adjustsFontSizeToFitWidth
        }
        set {
            self.titleLabel?.numberOfLines = 1
            self.titleLabel?.adjustsFontSizeToFitWidth = newValue;
            self.titleLabel?.lineBreakMode = .byClipping;
            self.titleLabel?.baselineAdjustment = .alignCenters
        }
    }
}

@IBDesignable
class DesignableView: UIView {
}

@IBDesignable
class DesignableButton: UIButton {
}

@IBDesignable
class DesignableLabel: UILabel {
}

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
}

//
//  MainMenuViewController.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 11/12/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import UIKit
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectWebSockets
import RealmSwift
import Realm
//import Sea_Battle_Shared_iOS
import Starscream


class MainMenuViewController: UIViewController{

    
    var message : String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //server()
        // Do any additional setup after loading the view.
        answer()
//        g.printA()
//        test()
//        sleep(5)
//        //while a == 0 {}
//        g.printA()
    }
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var previousButton: UIButton!
    
    var gamemode : String?
    var type : String?
    var gamename : String?
    var k = 0
    var singlePlayerGamesNames : [String] = []
    var multiplayerGamesNames : [String] = []
    var oneScreenGamesNames : [String] = []
    var currentGamesNames : [String] = []
    var games : [[String:Any]] = []
    var game : [String:Any] = [:]
    var t : [Ship] = []
    
    
    @IBOutlet weak var listButtons: UIStackView!
    
    @IBOutlet var buttons: [UIButton]!
    
    @IBAction func menuButton(_ sender: UIButton) {
        if gamemode != nil && type != nil && sender.currentTitle != "Back" && sender.currentTitle != "Previous" && sender.currentTitle != "Next"{
            gamename = sender.currentTitle
            for game in games {
                if game["name"] as? String == gamename {
                    self.game = game
                }
            }
            performSegue(withIdentifier: type!, sender: nil)
        }
        if gamemode == nil {
            gamemode = sender.currentTitle
            switch gamemode {
            case "SinglePlayer" : currentGamesNames = singlePlayerGamesNames
            case "Multiplayer" : currentGamesNames = multiplayerGamesNames
            case "OneScreen" : currentGamesNames = oneScreenGamesNames
            default : print("Wrong gamemode")
            }
            buttons[0].setTitle("Create", for: .normal)
            if gamemode != "Multiplayer" {
            buttons[1].setTitle("Load", for: .normal)
            }
            else {
               buttons[1].setTitle("Join", for: .normal)
            }
            buttons[2].setTitle("Back", for: .normal)
        }
        else {
            if sender.currentTitle != "Back" && type == nil{
                type = sender.currentTitle
            }
            if sender.currentTitle == "Back" {
                gamemode = nil
                type = nil
                gamename = nil
                buttons[0].setTitle("SinglePlayer", for: .normal)
                buttons[1].setTitle("OneScreen", for: .normal)
                buttons[2].setTitle("Multiplayer", for: .normal)
                for button in buttons {
                    button.isEnabled = true
                    button.isHidden = false
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
                k += 2
                pageCreator(gamesNames: currentGamesNames , gamesStartIndex: k)
            }
            if sender.currentTitle == "Previous"{
                k -= 2
                pageCreator(gamesNames: currentGamesNames , gamesStartIndex: k)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var gamemodeInt = 0
        switch gamemode {
        case "SinglePlayer" : gamemodeInt = 0
        case "OneScreen" : gamemodeInt = 1
        case "Multiplayer" : gamemodeInt = 2
        default : gamemodeInt = -1
        }
        if type == "Create" {
            if let PlacingVC = segue.destination as? PlacingShipsViewController{
                PlacingVC.game = Game(gamemode : gamemodeInt)
                if gamemodeInt == 2 {
                    PlacingVC.type = type
                }
                PlacingVC.game?.gamesNames = currentGamesNames
            }
        }
        if type == "Load" {
            if let GameVC = segue.destination as? GameViewController{
                GameVC.game = Game(game : game)
            }
        }
        if type == "Join"{
            if let PlacingVC = segue.destination as? PlacingShipsViewController{
                PlacingVC.game = Game(game1 : game)
                PlacingVC.type = type
                PlacingVC.game?.gamesNames = multiplayerGamesNames
                PlacingVC.badName = false
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if gamemode != nil && type == "Create"  && gamename == nil {
            return true
        }
        if gamemode != nil && type == "Load"  && gamename != nil {
            return true
        }
        if gamemode != nil && type == "Join"  && gamename != nil {
            return true
        }
        return false
    }
    
    func pageCreator ( gamesNames : [String] , gamesStartIndex : Int = 0) {
        if gamesNames.count > 2 {
            if gamesStartIndex + 2 < gamesNames.count {
                for i in gamesStartIndex..<gamesStartIndex + 2 {
                    buttons[i].setTitle(gamesNames[i], for: .normal)
                }
            }
            else {
                buttons[0].setTitle(gamesNames[gamesStartIndex], for: .normal)
                for i in 1..<2 {
                    buttons[i].isEnabled = false
                    buttons[i].isHidden = true
                }
            }
        }
        else  {
            for i in 0..<gamesNames.count {
                buttons[i].setTitle(gamesNames[i], for: .normal)
            }
            for i in gamesNames.count..<2 {
                buttons[i].isEnabled = false
                buttons[i].isHidden = true
            }
        }
        listButtons.isUserInteractionEnabled = true
        listButtons.isHidden = false
        if k+2 >= gamesNames.count {
            nextButton.isEnabled = false
        }
        else {
            nextButton.isEnabled = true
        }
        if k != 0 {
            previousButton.isEnabled = true
        }
        else {
            previousButton.isEnabled = false
        }
    }
    
    func server () {
        let url = URL(string: "http://localhost:3000/")!
        var request = URLRequest(url: url)
       // request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "id": 13,
            "name": "Jack & Jill"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
      

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
            print("responseString = \(String(describing: responseString))")
        }

        task.resume()
    }

    
//    func test () {
//        let url = URL(string: "http://localhost:8181/da")!
//        var request = URLRequest(url: url)
//       // request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        request.httpMethod = "POST"
//        let parameters: [String: Any] = [
//            "id": 13,
//            "name": "Jack & Jill"
//        ]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
//        
//      
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data,
//                let response = response as? HTTPURLResponse,
//                error == nil else {                                              // check for fundamental networking error
//                print("error", error ?? "Unknown error")
//                return
//            }
//
//            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
//                print("statusCode should be 2xx, but is \(response.statusCode)")
//                print("response = \(response)")
//                return
//            }
//
//            let responseString = String(data: data, encoding: .utf8)
//            print("responseString = \(String(describing: responseString))")
//        }
//
//        task.resume()
//    }
    
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
                    self.games = json as! [[String : Any]]
                    // print(json)
                    for k in array {
                        if let a = k["gamemode"] as? Int  {
                            if a == 0{
                            let p = k["name"] as! String
                            self.singlePlayerGamesNames.append(p)
                            }
                        }
                    }
                    for k in array {
                        if let a = k["gamemode"] as? Int  {
                            if a == 2{
                            let p = k["name"] as! String
                            self.multiplayerGamesNames.append(p)
                            }
                        }
                    }
                    for k in array {
                        if let a = k["gamemode"] as? Int  {
                            if a == 1{
                            let p = k["name"] as! String
                            self.oneScreenGamesNames.append(p)
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
    

}





extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

//
//  AppDelegate.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 10/1/19.
//  Copyright © 2019 Vlad Nechyporenko. All rights reserved.
//

import UIKit
import Firebase
import Starscream
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var gamesData: GamesData?
    var socket: Starscream.WebSocket?

    let notifications = LocalNotifications()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        gamesData = GamesData()
        notifications.notificationCenter.delegate = notifications
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // when user terminate application if game was in multiplayer mode, game should be deleted and opponent should be notified;
        // it happens when game is playing and when user who creates game waiting for oponent and terminate app
        // it`s not good to made such functions here but i didn`t found any other method to remove data from MongoDB
        // for firebase there is a func onDisconnectRemoveValue()
        if let game = gamesData?.currentGame, game.gameMode == .multiplayer {
            if let socket = socket {
                let data1 = ["email" : game.player_1.email, "gameName" : game.name, "coordinate" : 500] as [String: Any]
                let data2 = ["email" : game.player_2.email, "gameName" : game.name, "coordinate" : 500] as [String: Any]
                socket.write(data: try! JSONSerialization.data(withJSONObject: data1))
                socket.write(data: try! JSONSerialization.data(withJSONObject: data2))
            }
            let group = DispatchGroup()
            group.enter()
            if gamesData?.currentDatabase == .mongoDB {
                var request = URLRequest(url: URL(string: "http://localhost:3000/delete")!)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.httpMethod = "POST"
                request.httpBody = try! game.encode()
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let _ = data,
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
                    group.leave()
                }
                
                task.resume()
            }
            group.wait()
        }
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }


}


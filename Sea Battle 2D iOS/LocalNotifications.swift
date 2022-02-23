//
//  LocalNotifications.swift
//  Sea Battle 2D iOS
//
//  Created by Vlad Nechyporenko on 17.02.2022.
//  Copyright © 2022 Vlad Nechyporenko. All rights reserved.
//

import Foundation
import UserNotifications

// class that represents local notifications
class LocalNotifications: NSObject, UNUserNotificationCenterDelegate{
    
    enum Schedule {
        case now
        case everyday
        case seconds(Int)
        case everyweek
    }
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    private let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    private let snoozeAction = UNNotificationAction(identifier: "Snooze", title: "Snooze", options: [])
    private let deleteAction = UNNotificationAction(identifier: "Delete", title: "Delete", options: [.destructive])
    private let userActions = "User Actions"
    private let category: UNNotificationCategory
    
    func allowNotifications() {
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
    
    override init() {
        category = UNNotificationCategory(identifier: userActions, actions: [snoozeAction, deleteAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([category])
    }
    
    func checkIfNotificationsAvailable() -> Bool{
        var result = true
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                result = false
            }
        }
        return result
    }
    
    func scheduleNotification(title: String, body: String, id: String, schedule: Schedule) {
        
        let date = Date(timeIntervalSinceNow: -5)
        var timeTrigger: UNTimeIntervalNotificationTrigger?
        var dayTriger: UNCalendarNotificationTrigger?
        var request: UNNotificationRequest?
        
        switch schedule {
        case .everyday:
            let dateComponents = Calendar.current.dateComponents([.hour,.minute,.second,], from: date)
            dayTriger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .seconds(let seconds):
            timeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(seconds), repeats: false)
        case .now:
            timeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        case .everyweek:
            let dateComponents = Calendar.current.dateComponents([.weekday,.hour,.minute,.second,], from: date)
            dayTriger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        }
        
        let content = UNMutableNotificationContent()
        
        content.categoryIdentifier = userActions
        
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        if let timeTrigger = timeTrigger {
            request = UNNotificationRequest(identifier: id, content: content, trigger: timeTrigger)
        }
        else if let dayTriger = dayTriger {
            request = UNNotificationRequest(identifier: id, content: content, trigger: dayTriger)
        }
        
        if let request = request {
            notificationCenter.add(request) { (error) in
                if let error = error {
                    print("Error \(error.localizedDescription)")
                }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.identifier == "MainMenu" {
            print("User want to play the game")
        }
        
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            print("Default")
        case "Snooze":
            print("Snooze")
            scheduleNotification(title: "Sea Battle", body: "Come play the game", id: "MainMenu", schedule: .everyday)
        case "Delete":
            print("Delete")
        default:
            print("Unknown action")
        }
        
        completionHandler()
    }
    
    
}

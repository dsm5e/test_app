//
//  test_task_iosApp.swift
//  test_task_ios
//
//  Created by dsm 5e on 08.07.2025.
//

import SwiftUI
import UserNotifications

@main
struct test_task_iosApp: App {
    @StateObject private var workoutDataManager = WorkoutDataManager()
    
    init() {
        setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutDataManager)
        }
    }
    
    private func setupNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Сохранить тренировку",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Закрыть",
            options: []
        )
        
        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_COMPLETION",
            actions: [completeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([workoutCategory])
    }
}

//
//  AppDelegate.swift
//  Konverter
//
//  Created by ParadiseDuo on 2018/8/21.
//  Copyright © 2018年 ParadiseDuo. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.delegate = self

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: OperationQueue.main) { (noti) in
            NSApp.terminate(self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}


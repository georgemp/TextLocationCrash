//
//  AppDelegate.swift
//  TextLocationCrash
//
//  Created by George Philip Malayil on 06/10/23.
//

import Cocoa
import Logging

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var logger = {
        var logger = Logger(label: "in.roguemonkey.TextLocationCrash.AppDelegate")
        logger.logLevel = .error

        return logger
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}


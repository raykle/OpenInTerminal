//
//  FinderManager.swift
//  OpenInTerminalCore
//
//  Created by Cameron Ingham on 4/17/19.
//  Copyright © 2019 Cameron Ingham. All rights reserved.
//

import Cocoa
import ScriptingBridge

public class FinderManager {
    
    public static var shared = FinderManager()
    
    /// Get full path to front Finder window or selected file
    public func getFullPathToFrontFinderWindowOrSelectedFile() throws -> String {
        
        let finder = SBApplication(bundleIdentifier: Constants.Finder.id)! as FinderApplication
        
        var target: FinderItem
        
        guard let selection = finder.selection,
            let selectionItems = selection.get() else {
                throw OITError.cannotAccessFinder
        }
        
        if let firstItem = (selectionItems as! Array<AnyObject>).first {
            
            // Files or folders are selected
            target = firstItem as! FinderItem
        }
        else {
            
            // Check if there are opened finder windows
            guard let windows = finder.FinderWindows?(),
                let firstWindow = windows.firstObject else {
                    log("No Finder windows are opened or selected", .warn)
                    return ""
            }
            target = (firstWindow as! FinderFinderWindow).target?.get() as! FinderItem
        }
        
        guard let targetUrl = target.URL,
            let url = URL(string: targetUrl) else {
                log("target url nil", .warn)
                return ""
        }
        
        return url.absoluteString
    }
    
    /// Get path to front Finder window or selected file.
    /// If the selected one is file, return it's parent path.
    public func getPathToFrontFinderWindowOrSelectedFile() throws -> String {
        
        let fullPath = try getFullPathToFrontFinderWindowOrSelectedFile()
        
        guard fullPath != "" else { return "" }
        
        guard let url = URL(string: fullPath) else {
            throw OITError.wrongUrl
        }
        
        var isDirectory: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            log("file does not exist", .warn)
            return ""
        }
        
        // if the selected is a file, then delete last path component
        guard isDirectory.boolValue else {
            return url.deletingLastPathComponent().absoluteString
        }
        
        return url.absoluteString
    }
    
    /// Determine if the app exists in the `/Applications` folder
    private func applicationExists(_ application: String) -> Bool {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: "/Applications").contains("\(application).app")
        } catch {
            return false
        }
    }
    
    /// Determine if the user has installed the terminal
    public func terminalIsInstalled(_ terminalType: TerminalType) -> Bool {
        switch terminalType {
        case .terminal:
            return true
        case .iTerm, .hyper, .alacritty:
            return self.applicationExists(terminalType.rawValue)
        }
    }
    
    /// Determine if the user has installed the editor
    public func editorIsInstalled(_ editorType: EditorType) -> Bool {
        return self.applicationExists(editorType.fullName)
    }
}

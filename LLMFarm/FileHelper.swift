//
//  FileHelper.swift
//  LLMFarm
//
//  Created by guinmoon on 21.05.2023.
//

import Foundation
//import SwiftUI

func get_avalible_models() -> [String]?{
    var res: [String] = []
    do {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent("models")
        let items = try fileManager.contentsOfDirectory(atPath: destinationURL.path)
        for item in items {
            if item.contains(".bin"){
                res.append(item)
            }
        }
        return res
    } catch {
        // failed to read directory – bad permissions, perhaps?
    }
    return res
}


public func get_chat_info(_ chat_fname:String) -> Dictionary<String, AnyObject>? {
    do {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent("chats")
        let path = destinationURL.appendingPathComponent(chat_fname).path
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        let jsonResult_dict = jsonResult as? Dictionary<String, AnyObject>
        return jsonResult_dict
    } catch {
        
    }
    return nil
}

public func delete_chats(_ chats:[Dictionary<String, String>]) -> Bool{
    do{
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent("chats")
        
        for chat in chats {
            if chat["chat"] != nil{
                let path = destinationURL.appendingPathComponent(chat["chat"]!)
                try fileManager.removeItem(at: path)
            }
        }
        return true
    }
    catch{
        print(error)
    }
    return false
}

public func get_chat_list() -> [Dictionary<String, String>]?{
    var res: [Dictionary<String, String>] = []
    do {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent("chats")
        let files = try fileManager.contentsOfDirectory(atPath: destinationURL.path)
        for chatfile in files {
            if chatfile.contains(".json"){
                let info = get_chat_info(chatfile)!
                var title = chatfile
                var icon = "ava0"
                var model = ""
                if (info["title"] != nil){
                    title = info["title"] as! String
                }
                if (info["icon"] != nil){
                    icon = info["icon"] as! String
                }
                if (info["model"] != nil){
                    model = info["model"] as! String
                }
                let tmp_chat_info = ["title":title,"icon":icon, "message":"Hi there", "time": "10:30 AM","model":model,"chat":chatfile]
                res.append(tmp_chat_info)
            }
        }
        return res
    } catch {
        // failed to read directory – bad permissions, perhaps?
    }
    return res
}

//func get_config_by_model_name(_ model_name:String) -> Dictionary<String, AnyObject>?{
//    do {
////        let index = model_name.index(model_name.startIndex, offsetBy:model_name.count-4)
////        let model_name_prefix = String(model_name.prefix(upTo: index))
//        let fileManager = FileManager.default
//        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
//        let destinationURL = documentsPath!.appendingPathComponent("chats")
////        let path = destinationURL.appendingPathComponent(model_name_prefix+".json").path
//        let path = destinationURL.appendingPathComponent(model_name+".json").path
//        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
//        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
//        let jsonResult_dict = jsonResult as? Dictionary<String, AnyObject>
//        return jsonResult_dict
//    } catch {
//        // handle error
//    }
//    return nil
//}

func create_chat(_ options:Dictionary<String, Any>,edit_chat_dialog:Bool = false,chat_name: String = "") -> Bool{
    do {
        let fileManager = FileManager.default
        let jsonData = try JSONSerialization.data(withJSONObject: options, options: .prettyPrinted)
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent("chats")
        try fileManager.createDirectory (at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        let today = Date()
        // convert Date to TimeInterval (typealias for Double)
        let timeInterval = today.timeIntervalSince1970
        // convert to Integer
        let salt = "_" + String(Int(timeInterval))
        var fname = ""
        if edit_chat_dialog{
            fname = chat_name
        }else{
            fname = options["title"]! as! String + salt + ".json"
        }        
        let path = destinationURL.appendingPathComponent(fname)
        try jsonData.write(to: path)
        return true
    }
    catch {
        // handle error
        print(error)
    }
    return false
}

func get_file_name_without_ext(fileName:String) -> String{
    var components = fileName.components(separatedBy: ".")
    if components.count > 1 { // If there is a file extension
      components.removeLast()
      return components.joined(separator: ".")
    } else {
      return fileName
    }
}

func get_path_by_model_name(_ model_name:String) -> String? {
//#if os(iOS) || os(watchOS) || os(tvOS)
    do {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent("models")
        try fileManager.createDirectory (at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        let path = destinationURL.appendingPathComponent(model_name).path
        if fileManager.fileExists(atPath: path){
            return path
        }else{
            return nil
        }
        
    } catch {
        print(error)
    }
    return nil
//#elseif os(macOS)
//                                return model_name
//#else
//    println("Unknown OS version")
//#endif
   
}

func load_chat_history(_ fname:String) -> [Message]?{
    var res:[Message] = []
    do {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent("history")
        try fileManager.createDirectory (at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        let path = destinationURL.appendingPathComponent(fname).path
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        let jsonResult_dict = jsonResult as? [Dictionary<String, String>]
        for row in jsonResult_dict! {
            var tmp_msg = Message(sender: .system, text: "")
            if (row["id"] != nil){
                tmp_msg.id = UUID.init(uuidString: row["id"]!)!
            }
            if (row["sender"] == "user"){
                tmp_msg.sender = .user
            }
            if (row["text"] != nil){
                tmp_msg.text = row["text"]!
            }
            tmp_msg.state = .predicted(totalSecond: 0)
            res.append(tmp_msg)
        }
    }
    catch {
        // handle error
        var a=1
    }
    return res
}

//func saveBookmark(url: URL){
//    do {
//        let res = url.startAccessingSecurityScopedResource()
//        
//        let bookmarkData = try url.bookmarkData(
//            options: .withSecurityScope,
//            includingResourceValuesForKeys: nil,
//            relativeTo: nil
//        )
//
//        let a=1
////        return bookmarkData
//    } catch {
//        print("Failed to save bookmark data for \(url)", error)
//    }
//}


func copyModelToSandbox (url: URL) -> String?{
    do{
        if (CFURLStartAccessingSecurityScopedResource(url as CFURL)) { // <- here
            
//            let fileData = try? Data.init(contentsOf: url)
            let fileName = url.lastPathComponent
            
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            let destinationURL = documentsPath!.appendingPathComponent("models")
            try fileManager.createDirectory (at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            let actualPath = destinationURL.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: actualPath.path){
                return actualPath.lastPathComponent
            }
//#if os(macOS)
//            try fileManager.createSymbolicLink(atPath: actualPath.path, withDestinationPath: url.path)
//            saveBookmark(url:url)
//            return actualPath.lastPathComponent
//#else
            
            do {
                try FileManager.default.copyItem(at: url, to: actualPath)
//                try fileData?.write(to: actualPath)
//                if(fileData == nil){
//                    print("Permission error!")
//                }
//                else {
//                    print("Success.")
//                }
            } catch {
                print(error.localizedDescription)
            }
            CFURLStopAccessingSecurityScopedResource(url as CFURL) // <- and here
            return actualPath.lastPathComponent
//#endif
        }
        else {
            print("Permission error!")
            return nil
        }
    }catch {
        // handle error
        print(error)
        return nil
    }
}

func save_chat_history(_ messages_raw: [Message],_ fname:String){
    do {
        let fileManager = FileManager.default
        var messages: [Dictionary<String, AnyObject>] = []
        for message in messages_raw {
            let tmp_msg = ["id":message.id.uuidString as AnyObject,
                           "sender":String(describing: message.sender) as AnyObject,
                           "state":String(describing: message.state) as AnyObject,
                           "text":message.text as AnyObject]
            messages.append(tmp_msg)
        }
        let jsonData = try JSONSerialization.data(withJSONObject: messages, options: .prettyPrinted)
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentsPath!.appendingPathComponent("history")
        try fileManager.createDirectory (at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        let path = destinationURL.appendingPathComponent(fname)
        try jsonData.write(to: path)
        
    }
    catch {
        // handle error
    }
}

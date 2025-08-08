//
//  MessageImage.swift
//  LLMFarm
//
//  Created by guinmoon on 16.03.2024.
//

import SwiftUI
import PhotosUI

struct MessageImage: View {
    
    var message: Message
    var maxWidth:CGFloat = 300
    var maxHeight:CGFloat = 300
    
    func print_(_ str:String){
        print(str)
    }
    
    var body: some View {
        
        if message.attachment != nil && message.attachment_type != nil
            && message.attachment_type == "img"{
            let img_path = get_path_by_short_name(message.attachment!,dest: "cache/images")
            if img_path != nil{
#if os(macOS)
                let ns_img = NSImage(contentsOfFile: img_path!)
                if ns_img != nil{
                    let w = CGFloat(ns_img!.width * maxHeight/ns_img!.height)
                    Image(nsImage: ns_img!) //переделать
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: w,maxHeight: maxHeight)
                }
#elseif os(iOS)
                let ui_img = UIImage(contentsOfFile: img_path!)
                if ui_img != nil{
                    let w = CGFloat(ui_img!.cgImage!.width * Int(maxHeight)/ui_img!.cgImage!.height)
                    Image(uiImage: ui_img!.fixedOrientation)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: w,maxHeight: maxHeight)
                }
#endif
            }
        }
    }
}

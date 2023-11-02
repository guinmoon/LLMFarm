//
//  SettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 01.11.2023.
//

import SwiftUI


struct SettingsView: View {
    var body: some View {
        ZStack{
            //            Color("color_bg").edgesIgnoringSafeArea(.all)
            VStack{
                
                Text("Settings")
                    .fontWeight(.semibold)
                    .font(.title2)
                Spacer()
                
                VStack{
                    
                    NavigationLink(value: "Models"){
                        SettingsHeaderItem()
                    }
                    NavigationLink(value: "LoRA Adapters"){
                        SettingsHeaderItem()
                    }
                    
                }
                .frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            }
        }
    }
}

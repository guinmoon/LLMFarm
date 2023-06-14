//
//  SettingsView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 05/08/21.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack{
            Color("color_bg").edgesIgnoringSafeArea(.all)
            VStack{
                HStack{
                    Text("Settings")
                        .fontWeight(.semibold)
                        .font(.largeTitle)
                    Spacer()
                }
                
                ScrollView{

                    SettingsHeaderItem()
         
                    SettingsItem(icon: "person", title: "Account")
                    SettingsItem(icon: "bell", title: "Notifications and Sounds")
                    SettingsItem(icon: "lock", title: "Privacy & Security")
                    SettingsItem(icon: "archivebox", title: "Data and Storage")
                    SettingsItem(icon: "paintbrush", title: "Appearence")
                    SettingsItem(icon: "globe", title: "Language", selectedValue: "English")
                }
                .padding(.vertical)
  
            }
            .padding()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

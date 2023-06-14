//
//  ContentView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 03/08/21.
//

import SwiftUI



struct ContentView: View {
    
    @State private var tabSelection = 0
    @Binding var chat_selected: Bool
    @Binding var model_name: String
    @Binding var chat_name: String
    @Binding var title: String
    
//    private func select_model(modelName: String) -> Void{
//        viewModel.load_model_by_name(model_name: modelName)
//    }
    
    var body: some View {
        
        //Bottom tab
        TabView(selection: $tabSelection)  {
            
            //Chat
            ChatListView(tabSelection: $tabSelection,chat_selected: $chat_selected,model_name:$model_name,chat_name:$chat_name,title: $title)
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                }
                .tag(0)
            //Calls
//            ChatView()
//                .tabItem {
//                    Image(systemName: "message")
//                }
//                .tag(1)
            //Contacts
            ModelsView()
                .tabItem {
                    Image(systemName: "person.2")
                }
                .tag(2)
            //Settings
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                }
                .tag(3)
        }
        .accentColor(Color("color_primary"))
    }
    
    //Tabbar customization
//    init() {
//        UITabBar.appearance().barTintColor = UIColor(named: "color_bg")
//        UITabBar.appearance().isTranslucent = false
//    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(chat_selected: .constant(false),model_name: .constant("pythia-70m-q5_1.bin"),chat_name:.constant(""),title: .constant("title"))
            .preferredColorScheme(.dark)
    }
}

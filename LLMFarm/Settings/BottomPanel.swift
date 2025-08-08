//
//  BottomPanel.swift
//  LLMFarm
//
//  Created by guinmoon on 20.05.2023.
//

import SwiftUI

struct BottomPanelView: View {
    @Binding var tabIndex: Int
    @Binding var current_detail_view_name:String?
    var body: some View {
//        Splitter(orientation: .Horizontal,inset:  10, visibleThickness:  1, invisibleThickness: 0)
//            .opacity(0.5)
        HStack(){
            VStack{
                Button {
                    Task {
                        tabIndex=0
                        current_detail_view_name = "Chat"
                    }
                } label: {
                    Image(systemName: "message.fill")
                }.buttonStyle(.borderless)
                    
                    .font(.system(size: 20))
                    .foregroundColor(self.tabIndex == 0 ? .blue : .secondary)
                Text("Chats")
                    .font(.footnote)
                    .opacity(0.5)
            }.frame(maxWidth: .infinity, alignment: .center)
//                .ignoresSafeArea(.keyboard, edges: .bottom)
            
            VStack{
                Button {
                    Task {
                        tabIndex=1
                    }
                } label: {
                    Image(systemName: "gearshape.circle")
                }.buttonStyle(.borderless)
                    
                    .font(.system(size: 20))
                    .foregroundColor(self.tabIndex == 1 ? .blue : .secondary)
                Text("Settings")
                    .font(.footnote)
                    .opacity(0.5)
            }.frame(maxWidth: .infinity, alignment: .center)
//                .ignoresSafeArea(.keyboard, edges: .bottom)
        }.frame(height: 55)
            .background(.regularMaterial)
//            .ignoresSafeArea(.keyboard, edges: .bottom)
            
    }
}


//struct BottomPanelView_Previews: PreviewProvider {
//    static var previews: some View {
//        BottomPanelView(tabIndex: .constant(0),current_detail_view_name: .constant("Chat"))
//    }
//}

//
//  TabsView.swift
//  LLMFarm
//
//  Created by guinmoon on 18.10.2024.
//

import SwiftUI



struct AppSettingTabs : View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var index:Int
    
    
    var body: some View{
        VStack{
 
            TabButton(index: $index, targetIndex: 0, image: Image(systemName: "square.stack.3d.up.fill"), text: "Models")
#if os(macOS)
            .padding(.top,topSafeAreaInset()-20)
#else
            .padding(.top,UIApplication.shared.keyWindow?.safeAreaInsets.top)
#endif
            
            TabButton(index: $index, targetIndex: 1, image: Image(systemName: "square.and.arrow.down.on.square.fill"), text: "Download")
            .padding(.top,15)
            
            Spacer(minLength: 0)

            TabButton(index: $index, targetIndex: 2, image: Image(systemName: "info.circle.fill"), text: "Info")
//            .padding(.bottom)
#if os(macOS)
            .padding(.top,bottomSafeAreaInset())
#else
            .padding(.top,UIApplication.shared.keyWindow?.safeAreaInsets.bottom)
#endif
            

            
        }
        .padding(.vertical)
        // Fixed Width....
        .frame(width: 62)
        //        .background(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
        .background(.thinMaterial)
        .clipShape(CShape())
    }
}



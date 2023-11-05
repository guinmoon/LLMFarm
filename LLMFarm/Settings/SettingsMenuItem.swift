//
//  SettingsMenuItem.swift
//  ChatUI
//
//  Created by Guinmoon
//

import SwiftUI

struct SettingsMenuItem: View {
    
    public var icon:String
    public var name:String
    @Binding var current_detail_view_name:String?


    var body: some View {
        HStack{
            Button(action: {
                current_detail_view_name = name
            }){
                Image(systemName: icon)
                    .resizable()
                    
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 6){
                    HStack{
                        Text(name)
                            .fontWeight(.semibold)
                            .padding(.top, 3)
                        Spacer()
                    }
                }
                .padding(.horizontal, 10)
            }
            
        }
        .background( Color("color_bg_inverted").opacity(0.05))
    }
}

//
//  ContactItem.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 6/08/21.
//

import SwiftUI

struct ContactItem: View {
    
    var userImage: String = ""
    var userName: String = ""
    var userEmail: String = ""
    
    var body: some View {
        HStack{
            Image(userImage)
                .resizable()
                .background( Color("color_bg_inverted").opacity(0.05))
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 6){
                HStack{
                    Text(userName)
                        .fontWeight(.semibold)
                        .padding(.top, 3)
                    Spacer()
                    Image(systemName: "phone")
                        .foregroundColor(Color("color_primary"))
                        .padding(.horizontal)
                    Image(systemName: "bubble.right")
                        .foregroundColor(Color("color_primary"))
                }
                
                HStack{
                    Text(userEmail)
                        .foregroundColor(Color("color_bg_inverted").opacity(0.5))
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                }
                
                Divider()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 10)
        }
    }
}

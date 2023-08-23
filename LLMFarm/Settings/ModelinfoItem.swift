//
//  ContactItem.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 6/08/21.
//

import SwiftUI

struct ModelInfoItem: View {
    
    var modelIcon: String = ""
    @State var file_name: String = ""
    var description: String = ""
    
    func model_name_canged(_ new_name:String){
        let a = 1
    }
    
    var body: some View {
        HStack{
            Image(systemName: modelIcon)
                .resizable()
            //                .background( Color("color_bg_inverted").opacity(0.05))
                .padding(EdgeInsets(top: 7, leading: 5, bottom: 7, trailing: 5))
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 6){
                HStack
                {
#if os(macOS)
                    TextField("", text: $file_name)
//                    MacEditorTextView(text: $file_name, isEditable: true, onTextChange: model_name_canged)
//                        .frame(minWidth: 300,
//                                       maxWidth: .infinity,
//                                       minHeight: 20,
//                                       maxHeight: .infinity)
//                        .padding(.top)
#else
                    TextField("", text: $file_name)
#endif
                    //                        .onSubmit {
                    //                            let a = 1
                    //                        }
                    //                    Text(file_name)
                    //                        .fontWeight(.none)
                    //                        .padding(.top, 3)
                    //                    Spacer()
                    //                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    //                        .padding(.horizontal)
                    //                    Image(systemName: "bubble.right")
                    //                        .foregroundColor(Color("color_primary"))
                }
                
                HStack{
                    Text(description)
                    //                        .foregroundColor(Color("color_bg_inverted").opacity(0.5))
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                }
                
                Divider()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 10)
        }
    }
}

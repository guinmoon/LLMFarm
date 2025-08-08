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
    @State var orig_file_name: String = ""
    var description: String = ""
    var download_url: String = ""
    
    func model_name_canged(){
        let res = rename_file(orig_file_name,file_name,"models")
        if res {
            orig_file_name = file_name
        }else{
            print("Rename error!")
        }
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
                    Text(file_name)
//                        .frame( maxWidth: .infinity)
                        .frame( alignment: .leading)
//#if os(macOS)
//                    DidEndEditingTextField(text: $file_name, didEndEditing: { newName in
//                        model_name_canged()
//                    })
//#else
//                    TextField("", text: $file_name)
//                        .onSubmit {
//                            model_name_canged()
//                        }

                }
                
                HStack{
                    Text(description)
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                    
                }                
                
            }
            .padding(.horizontal, 10)

        }
    }
}

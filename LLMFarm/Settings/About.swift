//
//  About.swift
//  LLMFarm
//
//  Created by guinmoon on 20.10.2024.
//

import SwiftUI


struct About: View {
    let app_version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    var body: some View {
        VStack{
            HStack{
                Image("ava0_48")
                    .foregroundColor(.secondary)
                    .font(.system(size: 40))
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            Text("LLMFarm v\(app_version)\nAuthor Artem Savkin\n2024")
                .font(.footnote)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            
        }.opacity(0.4)
            .frame(maxWidth: .infinity,alignment: .center)
    }
}

//#Preview {
//    About()
//}

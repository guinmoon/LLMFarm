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
            GroupBox(label:
                        Text("About")
            ) {
                HStack{
                    Image("ava0_48")
                        .foregroundColor(.secondary)
                        .font(.system(size: 40))
                        .opacity(0.4)
                }
                .buttonStyle(.borderless)
                .controlSize(.large)
                Text("LLMFarm v\(app_version)\nAuthor Artem Savkin\n2024")
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            GroupBox(label:
                        Text("Help")
            ) {
                Link("Visit LLM Farm documentation site", destination: URL(string: "https://llmfarm.tech/docs/FAQ")!)
                    .font(.title3)
                    .padding()
                //                .foregroundStyle(.)
            }
        }
            .frame(maxWidth: .infinity,alignment: .center)
    }
}

//#Preview {
//    About()
//}

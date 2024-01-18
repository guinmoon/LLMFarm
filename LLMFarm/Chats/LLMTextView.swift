//
//  LLMTextView.swift
//  LLMFarm
//
//  Created by guinmoon on 05.12.2023.
//

import SwiftUI



struct LLMTextView: View {
    @Binding var placeholder: String
    @Binding var text: String
    var body: some View {
        TextEditor(text: self.$text)
        // make the color of the placeholder gray
#if os(macOS)
            .padding(.top, 15)
#else
            .padding(.top, 10)
            .listRowBackground(Color(uiColor: .systemGroupedBackground))
#endif
            .padding(.leading, 5)
            .lineSpacing(1)
            .font(.system(.body))
            .background {
                RoundedRectangle(cornerRadius: 8)
#if os(macOS)
                    .fill(Color(NSColor.textBackgroundColor))
#else
                    .fill(Color(UIColor.systemBackground))
#endif
                    .padding(.top,8)
            }
#if  os(iOS)
            .onAppear {
                // remove the placeholder text when keyboard appears
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (noti) in
                    withAnimation {
                        if self.text == placeholder {
                            self.text = ""
                        }
                    }
                }
                
                // put back the placeholder text if the user dismisses the keyboard without adding any text
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (noti) in
                    withAnimation {
                        if self.text == "" {
                            self.text = placeholder
                        }
                    }
                }
            }
#endif
    }
}

//#Preview {
//    LLMTextView(placeholder: .constant("type here"),text: .constant(""))
//}

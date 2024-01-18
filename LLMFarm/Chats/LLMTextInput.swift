//
//  LLMTextInput.swift
//  LLMFarm
//
//  Created by guinmoon on 17.01.2024.
//

import SwiftUI

public struct MessageInputViewHeightKey: PreferenceKey {
    /// Default height of 0.
    ///
    public static var defaultValue: CGFloat = 0
    

    
    /// Writes the received value to the `PreferenceKey`.
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


/// View modifier to write the height of a `View` to the ``MessageInputViewHeightKey`` SwiftUI `PreferenceKey`.
extension View {
    func messageInputViewHeight(_ value: CGFloat) -> some View {
        self.preference(key: MessageInputViewHeightKey.self, value: value)
    }
}

public struct LLMTextInput: View {

    private let messagePlaceholder: String
    @EnvironmentObject var aiChatModel: AIChatModel
    @State public var input_text: String = ""
    @State private var messageViewHeight: CGFloat = 0
    
    
    public var body: some View {
        HStack(alignment: .bottom) {
            TextField(messagePlaceholder, text: $input_text, axis: .vertical)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20)
#if os(macOS)
                        .stroke(Color(NSColor.systemGray), lineWidth: 0.2)
#else
                        .stroke(Color(UIColor.systemGray2), lineWidth: 0.2)
#endif
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.1))
                        }
                        .padding(.trailing, -42)
                }
                .lineLimit(1...5)
            Group {
                    sendButton
                        .disabled(input_text.isEmpty && !aiChatModel.predicting)
            }
                .frame(minWidth: 33)
        }
            .padding(.horizontal, 16)
#if os(macOS)
            .padding(.top, 2)
#else
            .padding(.top, 6)
#endif
            .padding(.bottom, 10)
            .background(.thinMaterial)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            messageViewHeight = proxy.size.height
                        }
                        .onChange(of: input_text) { msg in
                            messageViewHeight = proxy.size.height
                        }
                }
            }
            .messageInputViewHeight(messageViewHeight)
    }
    
    private var sendButton: some View {
        Button(
            action: {
                sendMessageButtonPressed()
            },
            label: {
                Image(systemName: aiChatModel.action_button_icon)
//                    .accessibilityLabel(String(localized: "SEND_MESSAGE", bundle: .module))
                    .font(.title2)
#if os(macOS)
                    .foregroundColor(input_text.isEmpty && !aiChatModel.predicting ? Color(.systemGray) : .accentColor)
#else
                    .foregroundColor(input_text.isEmpty && !aiChatModel.predicting ? Color(.systemGray5) : .accentColor)
#endif
            }
        )
        .buttonStyle(.borderless)
            .offset(x: -5, y: -7)
    }
    
    /// - Parameters:
    ///   - chat: The chat that should be appended to.
    ///   - messagePlaceholder: Placeholder text that should be added in the input field
    public init(
//        _ chat: Binding<Chat>,
        messagePlaceholder: String? = nil
    ) {
//        self._chat = chat
        self.messagePlaceholder = messagePlaceholder ?? "Message"
    }
    
    
    private func sendMessageButtonPressed() {
        Task {            
            if (aiChatModel.predicting){
                aiChatModel.stop_predict()
            }else
            {
                Task {
                    await aiChatModel.send(message: input_text)
                    input_text = ""
                }
            }
        }
        
    }

}
//
//#Preview {
//    LLMTextInput()
//}

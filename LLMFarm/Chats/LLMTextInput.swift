//
//  LLMTextInput.swift
//  LLMFarm
//
//  Created by guinmoon on 17.01.2024.
//

import SwiftUI

public struct MessageInputViewHeightKey: PreferenceKey {
    /// Default height of 0.
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
//    @Binding private var chat: Chat
    private let messagePlaceholder: String
    
//    @State private var speechRecognizer = SpeechRecognizer()
    @State private var message: String = ""
    @State private var messageViewHeight: CGFloat = 0
    
    
    public var body: some View {
        HStack(alignment: .bottom) {
            TextField(messagePlaceholder, text: $message, axis: .vertical)
//                .accessibilityLabel(String(localized: "MESSAGE_INPUT_TEXTFIELD", bundle: .module))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20)
#if os(macOS)
                        .stroke(Color(NSColor.gray), lineWidth: 0.2)
#else
                        .stroke(Color(UIColor.systemGray2), lineWidth: 0.2)
#endif
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.2))
                        }
                        .padding(.trailing, -42)
                }
                .lineLimit(1...5)
            Group {
//                if speechRecognizer.isAvailable && (message.isEmpty || speechRecognizer.isRecording) {
//                    microphoneButton
//                } else {
                    sendButton
                        .disabled(message.isEmpty)
//                }
            }
                .frame(minWidth: 33)
        }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            messageViewHeight = proxy.size.height
                        }
                        .onChange(of: message) { msg in
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
                Image(systemName: "arrow.up.circle.fill")
//                    .accessibilityLabel(String(localized: "SEND_MESSAGE", bundle: .module))
                    .font(.title)
#if os(macOS)
                    .foregroundColor(message.isEmpty ? Color(.systemGray) : .accentColor)
#else
                    .foregroundColor(message.isEmpty ? Color(.systemGray5) : .accentColor)
#endif
            }
        )
            .offset(x: -2, y: -3)
    }
    
//    private var microphoneButton: some View {
//        Button(
//            action: {
//                microphoneButtonPressed()
//            },
//            label: {
//                Image(systemName: "mic.fill")
//                    .accessibilityLabel(String(localized: "MICROPHONE_BUTTON", bundle: .module))
//                    .font(.title2)
//                    .foregroundColor(
//                        speechRecognizer.isRecording ? .red : Color(.systemGray2)
//                    )
//                    .scaleEffect(speechRecognizer.isRecording ? 1.2 : 1.0)
//                    .opacity(speechRecognizer.isRecording ? 0.7 : 1.0)
//                    .animation(
//                        speechRecognizer.isRecording ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
//                        value: speechRecognizer.isRecording
//                    )
//            }
//        )
//            .offset(x: -4, y: -6)
//    }
    
    
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
//        speechRecognizer.stop()
//        chat.append(ChatEntity(role: .user, content: message))
        message = ""
    }
    
//    private func microphoneButtonPressed() {
//        if speechRecognizer.isRecording {
//            speechRecognizer.stop()
//        } else {
//            Task {
//                do {
//                    for try await result in speechRecognizer.start() {
//                        if result.bestTranscription.formattedString.contains("send") {
//                            sendMessageButtonPressed()
//                        } else {
//                            message = result.bestTranscription.formattedString
//                        }
//                    }
//                }
//            }
//        }
//    }
}

#Preview {
    LLMTextInput()
}

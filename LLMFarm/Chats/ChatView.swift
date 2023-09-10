//
//  ChatView.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/18/23.
//

import SwiftUI


struct ChatView: View {
    
    @EnvironmentObject var aiChatModel: AIChatModel
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    @State
    private var inputText: String = ""
    
    
    
    @Binding var model_name: String
    @Binding var chat_selection: String?
    @Binding var title: String
    var close_chat: () -> Void
    @Binding var add_chat_dialog:Bool
    @Binding var edit_chat_dialog:Bool
    @State private var reload_button_icon: String = "arrow.counterclockwise.circle"
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    @Namespace var bottomID
    
    @FocusState
    private var isInputFieldFocused: Bool
    
    func scrollToBottom(with_animation:Bool = false) {
        let last_msg = aiChatModel.messages.last // try to fixscrolling and  specialized Array._checkSubscript(_:wasNativeTypeChecked:)
        if last_msg != nil && last_msg?.id != nil{
            if with_animation{
                withAnimation {
                    scrollProxy?.scrollTo(last_msg?.id, anchor: .bottom)
                }
            }else{
                scrollProxy?.scrollTo(last_msg?.id, anchor: .bottom)
            }
        }
    }
    
    func reload() async{
        if chat_selection == nil {
            return
        }
        print("\nreload\n")
        aiChatModel.stop_predict()
        await aiChatModel.prepare(model_name,chat_selection!)
        aiChatModel.messages = []
        aiChatModel.messages = load_chat_history(chat_selection!+".json")!
        aiChatModel.AI_typing = -Int.random(in: 0..<100000)
    }
    
    private func delayIconChange() {
        // Delay of 7.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            reload_button_icon = "arrow.counterclockwise.circle"
        }
    }
    
    var body: some View {
        ScrollViewReader { scrollView in
            VStack {
                List {
                    ForEach(aiChatModel.messages, id: \.id) { message in
                        MessageView(message: message).id(message.id)
                    }
                    .listRowSeparator(.hidden)
                }.onChange(of: aiChatModel.AI_typing){ ai_typing in
                    if (aiChatModel.predicting){
                        scrollToBottom(with_animation: true)
                    }else{
                        scrollToBottom(with_animation: false)
                    }
                }
                .listStyle(PlainListStyle())
                                                
                HStack {
                    switch aiChatModel.state {
                    case .none:
                        Text("")
                    case .loading:
                        ProgressView {
                            Text("Loading...")
                        }
                    case .completed:
                        HStack{
#if os(macOS)
                            DidEndEditingTextField(text: $inputText, didEndEditing: { input in})
                            //                                    .frame( alignment: .leading)
#else
                            TextField("Type your message...", text: $inputText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            //                            .focused($isInputFieldFocused)
#endif
                            
                            Button {
                                Task {
                                    let text = inputText
                                    inputText = ""
                                    if (aiChatModel.predicting){
                                        aiChatModel.stop_predict()
                                    }else
                                    {
                                        await aiChatModel.send(message: text)
                                    }
                                }
                            } label: {
                                Image(systemName: aiChatModel.action_button_icon)
                            }
                            .padding(.horizontal, 6.0)
                            .disabled((inputText.isEmpty && !aiChatModel.predicting))
                            .keyboardShortcut(.defaultAction)
#if os(macOS)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
#endif
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 5)
                        .padding(.bottom, 5)
                    }
                }
                .frame(height:50)
                .background(.regularMaterial)
//                .padding(.bottom)
//                .padding(.leading)
//                .padding(.trailing)
            }
            .navigationTitle($title)
            .toolbar {
                Button {
                    Task {
                        self.aiChatModel.chat = nil
                        reload_button_icon = "checkmark"
                        delayIconChange()
                    }
                } label: {
                    Image(systemName: reload_button_icon)
                }
                .disabled(aiChatModel.predicting)
                //                .font(.title2)
                
                Button {
                    Task {
                        //                        add_chat_dialog = true
                        edit_chat_dialog = true
                        //                        chat_selection = nil
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                //                .font(.title2)
            }
            .disabled(chat_selection == nil)
            .onAppear(){
                scrollProxy = scrollView
                scrollToBottom(with_animation: false)
            }
        }
        .onChange(of: chat_selection) { chat_name in
            Task {
                if chat_name == nil{
                    close_chat()
                }
                else{
                    //                    isInputFieldFocused = true
                    await self.reload()
                }
            }
        }
    }
}

//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView(chat_selected: .constant(true),model_name: .constant(""),chat_name:.constant(""),title: .constant("Title"),close_chat: {},add_chat_dialog:.constant(false),edit_chat_dialog:.constant(false))
//    }
//}

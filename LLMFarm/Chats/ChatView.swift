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
    
    @Namespace var bottomID
    
    @FocusState
    private var isInputFieldFocused: Bool
    

    
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
    
    var body: some View {
        ScrollViewReader { scrollView in
            VStack {
                List {
                    ForEach(0..<aiChatModel.messages.count, id: \.self) { index in
                        MessageView(message: aiChatModel.messages[index]).id(aiChatModel.messages[index].id)
                    }
                    .listRowSeparator(.hidden)
                }.onChange(of: aiChatModel.AI_typing){ ai_typing in
                    scrollView.scrollTo(aiChatModel.messages.last?.id, anchor: .bottom)
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
                        TextField("Type your message...", text: $inputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .focused($isInputFieldFocused)
                            
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
                }
                .padding(.bottom)
                .padding(.leading)
                .padding(.trailing)
            }
            .navigationTitle($title)
            .toolbar {
                Button {
                    Task {
                        self.aiChatModel.chat = nil
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
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
            .task {// fix autoscroll
                scrollView.scrollTo(aiChatModel.messages.last?.id, anchor: .bottom)
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

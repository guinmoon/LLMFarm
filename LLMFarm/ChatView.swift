//
//  ChatView.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/18/23.
//

import SwiftUI


struct ChatView: View {
    
//    @StateObject  var aiChatModel = AIChatModel()
    @EnvironmentObject var aiChatModel: AIChatModel
    @EnvironmentObject var orientationInfo: OrientationInfo
        
    @State
    private var inputText: String = ""
        
        
    
    @Binding var chat_selected: Bool
    @Binding var model_name: String
    @Binding var chat_name: String
    @Binding var title: String
    var close_chat: () -> Void
    @Binding var add_chat_dialog:Bool
    @Binding var edit_chat_dialog:Bool
    
    @Namespace var bottomID
    
    @FocusState
    private var isInputFieldFocused: Bool
    
//    private func select_model(modelName: String) -> Void{
//        aiChatModel.load_model_by_name(model_name: modelName)
//    }
    
    func reload() async{
        print("\nreload\n")
        aiChatModel.stop_predict()
        await aiChatModel.prepare(model_name,chat_name)
        aiChatModel.messages = []
        aiChatModel.messages = load_chat_history(chat_name+".json")!
        aiChatModel.AI_typing = -1
    }
    
    var body: some View {
        ScrollViewReader { scrollView in
            VStack {
                HStack{
                    if (orientationInfo.orientation == .portrait || orientationInfo.userInterfaceIdiom == .phone){
                        Button {
                            Task {
                                close_chat()
                                chat_selected = false
//                                aiChatModel.stop_predict()
//                                save_chat_history(aiChatModel.messages,chat_name+".json")
//                                chat_selected = false
                            }
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .padding(.horizontal, 16.0)
                        .font(.title)
                    }
                                        
                    Text(title)
                        .fontWeight(.semibold)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 5)
                    
                    Button {
                        Task {
                            self.aiChatModel.chat = nil
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                    }
                    .disabled(aiChatModel.predicting)
                    .padding(.horizontal, 16.0)
                    .font(.title2)
                    
                    Button {
                        Task {
                            add_chat_dialog = true
                            edit_chat_dialog = true
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .padding(.horizontal, 16.0)
                    .font(.title2)
                }
//                .background( Color("color_bg_inverted").opacity(0.05))
                .padding(.top,10)
                .buttonStyle(.borderless)
#if os(macOS)
                .frame(minHeight: 45)
#endif
                
//                Divider()
//                    .padding(.bottom, 20)
                
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
                    case .none, .loading:
                        ProgressView {
                            Text("Loading...")
                        }
                    case .completed:
                        TextField("Type your message...", text: $inputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isInputFieldFocused)
                        
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
            }
            .navigationTitle("Chat")
            .task {
                print(chat_name)
                await self.reload()
                isInputFieldFocused = true
            }
            
        }
        .onChange(of: chat_name) { chat_name in
            Task {
                print(chat_name)
                await self.reload()
            }
        }
        
    }
}

//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView(chat_selected: .constant(true),model_name: .constant(""),chat_name:.constant(""),title: .constant("Title"),close_chat: {},add_chat_dialog:.constant(false),edit_chat_dialog:.constant(false))
//    }
//}

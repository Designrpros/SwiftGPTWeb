import SwiftUI

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var messageText = ""
    private let bot = GPTWebSearchBot()
    private let webCrawler = WebCrawler()
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(messages.indices, id: \.self) { index in
                            ChatBubble(message: messages[index].text, isUser: messages[index].isUser)
                                .id(index)
                        }
                    }
                    .onChange(of: messages) { _ in
                        if let lastMessageIndex = messages.indices.last {
                            scrollViewProxy.scrollTo(lastMessageIndex, anchor: .bottom)
                        }
                    }
                }
            }
            .padding(.horizontal)
            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(8)
                Button(action: sendMessage) {
                    Text("Send")
                }
                .padding(8)
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        messages.append(Message(text: "You: \(messageText)", isUser: true))
        
        if messageText.lowercased().starts(with: "crawl") {
            let urlString = messageText.replacingOccurrences(of: "crawl", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            webCrawler.crawl(urlString: urlString) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let content):
                        messages.append(Message(text: "Bot: Here is the content of the link: \n\(content)", isUser: false))
                    case .failure(let error):
                        messages.append(Message(text: "Bot: Error fetching link content: \(error.localizedDescription). Please try again later.", isUser: false))
                    }
                }
            }
        } else {
            bot.chat(message: messageText) { response in
                DispatchQueue.main.async {
                    messages.append(Message(text: "Bot: \(response)", isUser: false))
                }
            }
        }
        
        messageText = ""
    }

    }
    
    struct ChatBubble: View {
        let message: String
        let isUser: Bool
        
        var body: some View {
            HStack {
                if isUser {
                    Spacer()
                }
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(isUser ? Color.blue : Color.gray)
                    .cornerRadius(16)
                    .padding(.horizontal, isUser ? 12 : 0)
                if !isUser {
                    Spacer()
                }
            }
        }
    }

import Foundation
import SwiftyJSON


class GPTWebSearchBot {
    let googleApiKey = "AIzaSyCKj_D27aZ97bszhBjLlP9voFZRAqiEpMk"
    let searchEngineId = "c50758dcab85643f2"
    let openaiApiKey = "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"
    private let webCrawler = WebCrawler()
    
    func bot(query: String, completion: @escaping (String) -> Void) {
        search(query: query) { searchResults in
            if searchResults.isEmpty {
                completion("I'm sorry, I couldn't find any results for that.")
            } else {
                let resultString = searchResults.map { "- \($0.title)\n\($0.link)" }.joined(separator: "\n\n")
                let message = "Here are the top search results:\n\n\(resultString)\n\nWhich one would you like me to open?"
                self.chat(message: message) { response in
                    let crawlContentKeyword = "Crawl"
                    if response.contains(crawlContentKeyword) {
                        let urlString = response.replacingOccurrences(of: crawlContentKeyword, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        self.openLink(urlString, crawlContent: true) { response in
                            completion(response)
                        }
                    } else {
                        completion(response)
                    }
                }
            }
        }
    }

    
    private func search(query: String, completion: @escaping ([GPTWebSearchBot.SearchResult]) -> Void) {
        let apiUrl = "https://www.googleapis.com/customsearch/v1"
        let urlComponents = NSURLComponents(string: apiUrl)!
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: googleApiKey),
            URLQueryItem(name: "cx", value: searchEngineId),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "num", value: "10")
        ]
        
        let request = URLRequest(url: urlComponents.url!)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let data = data {
                let json = try? JSON(data: data)
                let searchResults = json?["items"].arrayValue.compactMap { GPTWebSearchBot.SearchResult(json: $0) } ?? []
                completion(searchResults)
            } else {
                completion([])
            }
        }
        task.resume()
    }
    
    func openLink(_ urlString: String, crawlContent: Bool = false, completion: @escaping (String) -> Void) {
        guard let url = URL(string: urlString) else {
            completion("Invalid URL. Please provide a valid URL.")
            return
        }
        
        if crawlContent {
            webCrawler.crawl(urlString: urlString) { result in
                switch result {
                case .success(let content):
                    completion("Here is the content of the link: \n\(content)")
                case .failure(let error):
                    completion("Error fetching link content: \(error.localizedDescription). Please try again later.")
                }
            }
        } else {
            NSWorkspace.shared.open(url)
            completion("Opening link...")
        }
    }
    
    public func chat(message: String, completion: @escaping (String) -> Void) {
        let apiUrl = URL(string: "https://api.openai.com/v1/chat/completions")!
        let predefinedPrompt = "You can access and open links on the web as well as files."
        let prompt = "Human: \(predefinedPrompt)\nHuman: \(message)\nAI:"
        let json: [String: Any] = [
            "model": "gpt-4",
            "messages": [["role": "system", "content": "You are a helpful assistant."], ["role": "user", "content": predefinedPrompt], ["role": "user", "content": message]],
            "max_tokens": 5000,
            "temperature": 0.7,
            "stop": ["\n\n"]
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("Bearer \(openaiApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "Unknown error")
                completion("")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let choice = choices.first,
                   let message = choice["message"] as? [String: Any],
                   let text = message["content"] as? String {
                    
                    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    let crawlContentKeyword = "Crawl content"
                    
                    if trimmedText.contains(crawlContentKeyword) {
                        if let url = URL(string: trimmedText.replacingOccurrences(of: crawlContentKeyword, with: "").trimmingCharacters(in: .whitespacesAndNewlines)), url.scheme != nil {
                            self.openLink(url.absoluteString, crawlContent: true) { _ in }
                            completion("Crawling content and opening link...")
                        } else {
                            completion("Invalid URL. Please provide a valid URL.")
                        }
                    } else {
                        // Check if the message contains a link and open it in the default browser
                        if let url = URL(string: trimmedText), url.scheme != nil {
                            self.openLink(url.absoluteString) { _ in }
                            completion("Opening link...")
                        } else {
                            completion(trimmedText)
                        }
                    }
                }
            } catch let parsingError {
                print("Error: \(parsingError)")
                completion("")
            }
        }
        task.resume()
    }
    
    struct SearchResult {
        let title: String
        let link: String
        
        init?(json: JSON) {
            guard let title = json["title"].string,
                  let link = json["link"].string
            else {
                return nil
            }
            
            self.title = title
            self.link = link
        }
    }
}

let bot = GPTWebSearchBot()

while true {
    print("Enter your command (type 'exit' to quit):")
    if let input = readLine() {
        if input.lowercased() == "exit" {
            break
        }
        bot.bot(query: input) { response in
            print("Bot response: \(response)")
        }
    }
}

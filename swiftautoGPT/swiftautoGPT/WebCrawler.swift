import Foundation
import SwiftSoup

class WebCrawler {
    func crawl(urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(WebCrawlerError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(WebCrawlerError.dataError))
                return
            }
            
            do {
                let document = try SwiftSoup.parse(html)
                let parsedContent = try self.parseDocument(document)
                completion(.success(parsedContent))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func parseDocument(_ document: Document) throws -> String {
        // Select headings, paragraphs, and list items
        let relevantElements = try document.select("h1, h2, h3, h4, h5, h6, p, li")
        
        // Extract the text content from each element, filter out empty strings, and join the results with newlines
        let textContent = relevantElements.array().compactMap { try? $0.ownText() }.filter { !$0.isEmpty }.joined(separator: "\n\n")
        
        return textContent
    }


    
    enum WebCrawlerError: Error {
        case invalidURL
        case dataError
    }
}

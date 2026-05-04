import Foundation

/// Delegate nhận luồng dữ liệu thời gian thực
public protocol SSEClientDelegate: AnyObject {
    func sseClient(_ client: SSEClient, didReceiveEvent eventName: String?, message: String)
    func sseClient(_ client: SSEClient, didEncounterError error: Error)
}

/// Trình xử lý kết nối Server-Sent Events (SSE).
/// Rất quan trọng để lắng nghe trạng thái Ghế (Seat) thay đổi theo thời gian thực khi nhiều người cùng đặt vé.
public final class SSEClient: NSObject, URLSessionDataDelegate {
    
    public weak var delegate: SSEClientDelegate?
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var url: URL
    
    public init(url: URL) {
        self.url = url
        super.init()
    }
    
    /// Bắt đầu mở luồng kết nối liên tục tới Server
    public func connect() {
        let configuration = URLSessionConfiguration.default
        // Tắt timeout để giữ luồng sống liên tục
        configuration.timeoutIntervalForRequest = TimeInterval(Int.max)
        configuration.timeoutIntervalForResource = TimeInterval(Int.max)
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // Đính Token bảo mật
        if let token = KeychainWrapper.shared.get(forKey: "access_token") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        task = session?.dataTask(with: request)
        task?.resume()
        print("Đã bắt đầu kết nối SSE tới: \(url.absoluteString)")
    }
    
    /// Đóng kết nối khi rời khỏi màn hình Sơ đồ ghế
    public func disconnect() {
        task?.cancel()
        session?.invalidateAndCancel()
        task = nil
        session = nil
        print("Đã đóng kết nối SSE")
    }
    
    // MARK: - URLSessionDataDelegate
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let messageString = String(data: data, encoding: .utf8) else { return }
        
        // Phân tích cú pháp cơ bản của SSE (data: {...}\n\n)
        let lines = messageString.components(separatedBy: .newlines)
        var currentEvent: String? = nil
        var currentData: String = ""
        
        for line in lines {
            if line.hasPrefix("event:") {
                currentEvent = line.replacingOccurrences(of: "event:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                currentData += line.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.isEmpty && !currentData.isEmpty {
                // Đã đọc xong một Block Event
                DispatchQueue.main.async {
                    self.delegate?.sseClient(self, didReceiveEvent: currentEvent, message: currentData)
                }
                currentData = ""
                currentEvent = nil
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            // Loại trừ lỗi do chúng ta chủ động Cancel
            if (error as NSError).code != NSURLErrorCancelled {
                DispatchQueue.main.async {
                    self.delegate?.sseClient(self, didEncounterError: error)
                }
            }
        }
    }
}

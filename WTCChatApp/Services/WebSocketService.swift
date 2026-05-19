//
//  WebSocketService.swift
//  WTCChatApp
//
//  Created by WTC Challenge — Sprint 2
//

import Foundation
import Combine

class WebSocketService: ObservableObject {
    static let shared = WebSocketService()

    @Published var newMessage: Message?
    @Published var newNotification: AppNotification?

    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var userId: String?
    private var subscriptionCounter = 0

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = ISO8601DateFormatter().date(from: str) { return date }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }
        return d
    }()

    private init() {}

    func connect(userId: String) {
        guard !isConnected else { return }
        self.userId = userId

        guard let url = URL(string: Constants.wsBaseURL) else { return }

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        sendStompConnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sendStompSubscribe(destination: "/topic/messages/\(userId)", id: "msg-sub")
            self?.sendStompSubscribe(destination: "/topic/notifications/\(userId)", id: "notif-sub")
            self?.isConnected = true
            self?.receiveMessages()
        }
    }

    func disconnect() {
        isConnected = false
        sendStompDisconnect()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    func cleanup() {
        disconnect()
    }

    // MARK: - STOMP Protocol

    private func sendStompConnect() {
        let frame = "CONNECT\naccept-version:1.2\nheart-beat:0,0\n\n\0"
        webSocketTask?.send(.string(frame)) { error in
            if let error = error {
                print("WebSocket CONNECT error: \(error)")
            }
        }
    }

    private func sendStompSubscribe(destination: String, id: String) {
        let frame = "SUBSCRIBE\nid:\(id)\ndestination:\(destination)\n\n\0"
        webSocketTask?.send(.string(frame)) { error in
            if let error = error {
                print("WebSocket SUBSCRIBE error: \(error)")
            }
        }
    }

    private func sendStompDisconnect() {
        let frame = "DISCONNECT\n\n\0"
        webSocketTask?.send(.string(frame)) { _ in }
    }

    private func receiveMessages() {
        guard isConnected else { return }

        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleStompFrame(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleStompFrame(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessages()

            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.isConnected = false
            }
        }
    }

    private func handleStompFrame(_ text: String) {
        guard let parsed = parseStompFrame(text) else { return }

        guard parsed.command == "MESSAGE" else { return }

        let destination = parsed.headers["destination"] ?? ""
        let body = parsed.body

        guard let data = body.data(using: .utf8) else { return }

        if destination.contains("/topic/messages/") {
            if let message = try? decoder.decode(Message.self, from: data) {
                DispatchQueue.main.async {
                    self.newMessage = message
                }
            }
        } else if destination.contains("/topic/notifications/") {
            if let notification = try? decoder.decode(AppNotification.self, from: data) {
                DispatchQueue.main.async {
                    self.newNotification = notification
                }
            }
        }
    }

    private func parseStompFrame(_ text: String) -> (command: String, headers: [String: String], body: String)? {
        let cleanText = text.replacingOccurrences(of: "\0", with: "")

        let headerSection: String
        let body: String
        if let range = cleanText.range(of: "\n\n") {
            headerSection = String(cleanText[cleanText.startIndex..<range.lowerBound])
            body = String(cleanText[range.upperBound...])
        } else {
            headerSection = cleanText
            body = ""
        }

        let lines = headerSection.components(separatedBy: "\n")
        guard !lines.isEmpty, !lines[0].isEmpty else { return nil }

        let command = lines[0]
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                headers[parts[0]] = parts.dropFirst().joined(separator: ":")
            }
        }

        return (command, headers, body)
    }
}

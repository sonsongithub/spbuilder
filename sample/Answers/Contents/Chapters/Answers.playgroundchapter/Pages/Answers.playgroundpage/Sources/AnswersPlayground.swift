// AnswersPlayground.swift

import UIKit
import PlaygroundSupport

private let answersLiveViewClient = AnswersLiveViewClient()

/// Shows a string in the current playground page's live view.
public func show(_ string: String) {
    answersLiveViewClient.show(string)
}

/// Asks for a string in the current playground page's live view.
public func ask(_ string: String? = nil) -> String {
    return answersLiveViewClient.ask(string)
}

// MARK: - LiveView Commands

public enum AnswersLiveViewCommand {
    case show(String)
    case ask(String)
    case submit(String)
    case clear
    
    public init?(_ message: PlaygroundValue) {
        guard case let .dictionary(dict) = message else {
            return nil
        }
        
        guard case let .string(command)? = dict["Command"] else {
            return nil
        }
        
        switch command {
        case "Show":
            guard case let .string(string)? = dict["String"] else {
                return nil
            }
            
            self = .show(string)
        case "Ask":
            guard case let .string(string)? = dict["String"] else {
                return nil
            }
            
            self = .ask(string)
        case "Submit":
            guard case let .string(string)? = dict["String"] else {
                return nil
            }
            
            self = .submit(string)
        case "Clear":
            self = .clear
        default:
            return nil
        }
    }
    
    private var message: PlaygroundValue {
        switch self {
        case .show(let string):
            let dict: [String: PlaygroundValue] = [
                "Command": .string("Show"),
                "String": .string(string),
            ]
            return .dictionary(dict)
        case .ask(let string):
            let dict: [String: PlaygroundValue] = [
                "Command": .string("Ask"),
                "String": .string(string),
            ]
            return .dictionary(dict)
        case .submit(let string):
            let dict: [String: PlaygroundValue] = [
                "Command": .string("Submit"),
                "String": .string(string),
            ]
            return .dictionary(dict)
        case .clear:
            let dict: [String: PlaygroundValue] = [
                "Command": .string("Clear")
            ]
            return .dictionary(dict)
        }
    }
}

extension PlaygroundLiveViewMessageHandler {
    public func send(_ command: AnswersLiveViewCommand) {
        self.send(command.message)
    }
}

// MARK: - LiveView Client

private class AnswersLiveViewClient : PlaygroundRemoteLiveViewProxyDelegate  {
    var responses: [String] = []
    
    init() {
    }
    
    func show(_ string: String) {
        assert(Thread.isMainThread())
        
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            return
        }
        
        liveViewMessageHandler.send(AnswersLiveViewCommand.show(string))
        RunLoop.main().run(until: Date(timeIntervalSinceNow: 0.2))
    }
    
    func ask(_ string: String? = nil) -> String {
        assert(Thread.isMainThread())
        
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            return ""
        }
        
        liveViewMessageHandler.delegate = self
        liveViewMessageHandler.send(AnswersLiveViewCommand.ask(string ?? "Input"))
        
        repeat {
            RunLoop.main().run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.1))
        } while responses.count == 0
        
        return responses.remove(at: 0)
    }
    
    // MARK: - PlaygroundRemoteLiveViewProxyDelegate Methods
    
    func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
    }
    
    func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy, received message: PlaygroundValue) {
        guard let command = AnswersLiveViewCommand(message) else {
            return
        }
        
        if case .submit(let string) = command {
            responses.append(string)
        }
    }
}

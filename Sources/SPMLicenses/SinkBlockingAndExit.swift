import Foundation
import Combine
import Darwin

extension Publisher {
    /// This method is to be called from scripts, allowing the console to wait for the completion of an asynchronous task. This blocks the main queue and should never be used outside of a script.
    /// - Parameters:
    ///   - receiveCompletion: regular completion block from `sink`
    ///   - receiveValue: regular event block from `sink`
    /// - Returns: a cancellable task that will run blocking the main queue anyway, so it can be discarded
    @available(macOS, introduced: 10.15)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @discardableResult
    public func sinkBlocking(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) -> Void
    ) -> AnyCancellable {
        let group = DispatchGroup()

        group.enter()
        group.notify(queue: DispatchQueue.main) {}

        defer { dispatchMain() }

        return sink(
            receiveCompletion: { completion in
                receiveCompletion(completion)
                group.leave()
            },
            receiveValue: receiveValue
        )
    }
}

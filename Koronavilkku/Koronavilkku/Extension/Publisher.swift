import Combine

extension Publisher {
    /// Shares the upstream publisher value to multiple subscribers
    ///
    /// This is basically a `CurrentValueSubject` equivalent of `share()`: it remembers
    /// the previous value and every new subscriber will receive it on connect.
    ///
    /// * Parameter defaultValue: The initial value that will be published before any
    ///                           values have been received from upstream.
    func shareCurrent(defaultValue: Output) -> AnyPublisher<Output, Failure> {
        multicast(subject: CurrentValueSubject<Output, Failure>(defaultValue))
            .autoconnect()
            .eraseToAnyPublisher()
    }

    /// Shares the upstream publisher value to multiple subscribers without a default value
    ///
    /// Instead of publishing a default value when the upstream has not yet published a
    /// value, waits until there's a value to be passed along.
    func shareCurrent() -> AnyPublisher<Output, Failure> {
        map(Optional.init)
            .shareCurrent(defaultValue: nil)
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}

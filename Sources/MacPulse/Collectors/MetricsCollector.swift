import Foundation

/// A type that collects system metrics of a specific kind.
///
/// `collect()` is `mutating` because collectors track previous sample state
/// (e.g., CPU ticks, network byte counters) to compute deltas between calls.
public protocol MetricsCollector<Metrics> {
    associatedtype Metrics: Sendable
    mutating func collect() -> Metrics
}

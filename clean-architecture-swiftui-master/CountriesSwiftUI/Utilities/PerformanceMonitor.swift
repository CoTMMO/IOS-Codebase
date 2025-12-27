//
//  PerformanceMonitor.swift
//  CountriesSwiftUI
//
//  Performance monitoring utilities for the core module
//

import Foundation
import UIKit

/// Performance monitoring and optimization utilities
@MainActor
final class PerformanceMonitor {
    
    // MARK: - Shared Instance
    
    static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    
    private var memoryWarnings: Int = 0
    private var lastMemoryWarningTime: Date?
    private var performanceMetrics: [String: PerformanceMetric] = [:]
    private let metricsQueue = DispatchQueue(label: "com.countries.performance.metrics", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {
        setupMemoryWarningObserver()
        startPeriodicMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Record a performance metric
    func recordMetric(_ name: String, duration: TimeInterval, metadata: [String: Any]? = nil) {
        metricsQueue.async { [weak self] in
            let metric = PerformanceMetric(
                name: name,
                duration: duration,
                timestamp: Date(),
                metadata: metadata
            )
            
            self?.performanceMetrics[name] = metric
            
            // Log slow operations
            if duration > 1.0 {
                print("⚠️ Slow operation detected: \(name) took \(duration)s")
            }
        }
    }
    
    /// Get current memory usage
    func getCurrentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return MemoryUsage(
                residentSize: info.resident_size,
                virtualSize: info.virtual_size
            )
        } else {
            return MemoryUsage(residentSize: 0, virtualSize: 0)
        }
    }
    
    /// Check if memory pressure is high
    func isMemoryPressureHigh() -> Bool {
        let memoryUsage = getCurrentMemoryUsage()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryPressureThreshold: Double = 0.8 // 80% of total memory
        
        return Double(memoryUsage.residentSize) > (Double(totalMemory) * memoryPressureThreshold)
    }
    
    /// Get performance report
    func getPerformanceReport() -> PerformanceReport {
        let memoryUsage = getCurrentMemoryUsage()
        let memoryPressure = isMemoryPressureHigh() ? "High" : "Normal"
        
        return PerformanceReport(
            timestamp: Date(),
            memoryUsage: memoryUsage,
            memoryPressure: memoryPressure,
            memoryWarnings: memoryWarnings,
            lastMemoryWarning: lastMemoryWarningTime,
            metrics: Array(performanceMetrics.values)
        )
    }
    
    /// Clear performance metrics
    func clearMetrics() {
        metricsQueue.async { [weak self] in
            self?.performanceMetrics.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        memoryWarnings += 1
        lastMemoryWarningTime = Date()
        
        #if DEBUG
        print("⚠️ Memory warning received (\(memoryWarnings) total)")
        #endif
        
        // Trigger cleanup in all handlers
        NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
    }
    
    private func startPeriodicMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performPeriodicCheck()
        }
    }
    
    private func performPeriodicCheck() {
        let memoryUsage = getCurrentMemoryUsage()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        
        #if DEBUG
        let memoryPercentage = (Double(memoryUsage.residentSize) / Double(totalMemory)) * 100
        print("Memory usage: \(memoryPercentage.rounded(toPlaces: 2))% (\(memoryUsage.residentSize / 1024 / 1024)MB)")
        #endif
        
        // Trigger cleanup if memory usage is high
        if isMemoryPressureHigh() {
            NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
        }
    }
}

// MARK: - Data Structures

struct MemoryUsage {
    let residentSize: UInt64 // Physical memory used
    let virtualSize: UInt64  // Virtual memory used
}

struct PerformanceMetric {
    let name: String
    let duration: TimeInterval
    let timestamp: Date
    let metadata: [String: Any]?
}

struct PerformanceReport {
    let timestamp: Date
    let memoryUsage: MemoryUsage
    let memoryPressure: String
    let memoryWarnings: Int
    let lastMemoryWarning: Date?
    let metrics: [PerformanceMetric]
}

// MARK: - Extensions

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Notification.Name {
    static let memoryPressureDetected = Notification.Name("MemoryPressureDetected")
}

// MARK: - Convenience Functions

extension PerformanceMonitor {
    /// Measure execution time of a closure
    static func measure<T>(_ name: String, _ closure: () -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = closure()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        shared.recordMetric(name, duration: timeElapsed)
        return result
    }
    
    /// Measure async execution time
    static func measureAsync<T>(_ name: String, _ asyncClosure: @escaping () async -> T, completion: @escaping (T) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        Task {
            let result = await asyncClosure()
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            await MainActor.run {
                shared.recordMetric(name, duration: timeElapsed)
                completion(result)
            }
        }
    }
}

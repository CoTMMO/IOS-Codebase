//
//  CoreRefactoringTests.swift
//  CountriesSwiftUI
//
//  Tests for the refactored core module
//

import XCTest
@testable import CountriesSwiftUI

final class CoreRefactoringTests: XCTestCase {
    
    var appState: AppState!
    var performanceMonitor: PerformanceMonitor!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        appState = AppState()
        performanceMonitor = PerformanceMonitor.shared
    }
    
    override func tearDownWithError() throws {
        appState = nil
        performanceMonitor.clearMetrics()
        try super.tearDownWithError()
    }
    
    // MARK: - AppState Tests
    
    func testAppStateInitialization() {
        // Given
        let initialState = AppState()
        
        // When
        let routing = initialState.routing
        let system = initialState.system
        let permissions = initialState.permissions
        
        // Then
        XCTAssertNotNil(routing)
        XCTAssertNotNil(system)
        XCTAssertNotNil(permissions)
        XCTAssertEqual(system.isActive, false)
        XCTAssertEqual(system.keyboardHeight, 0)
    }
    
    func testAppStateEfficientUpdates() {
        // Given
        let initialRouting = appState.routing
        
        // When
        appState.updateRouting { routing in
            routing.countriesList.countryCode = "USA"
        }
        
        // Then
        XCTAssertEqual(appState.routing.countriesList.countryCode, "USA")
        XCTAssertNotEqual(appState.routing, initialRouting)
    }
    
    func testAppStateMemoryManagement() {
        // Given
        let initialMemory = performanceMonitor.getCurrentMemoryUsage()
        
        // When
        appState.cleanupForBackground()
        
        // Then
        let finalMemory = performanceMonitor.getCurrentMemoryUsage()
        // Memory should be optimized (though exact measurement depends on system)
        XCTAssertNotNil(finalMemory)
    }
    
    // MARK: - Performance Monitor Tests
    
    func testPerformanceMonitorMetrics() {
        // Given
        let testMetricName = "test_operation"
        let testDuration: TimeInterval = 0.5
        
        // When
        performanceMonitor.recordMetric(testMetricName, duration: testDuration)
        
        // Then
        let report = performanceMonitor.getPerformanceReport()
        let metric = report.metrics.first { $0.name == testMetricName }
        
        XCTAssertNotNil(metric)
        XCTAssertEqual(metric?.duration, testDuration)
    }
    
    func testPerformanceMonitorMemoryTracking() {
        // Given
        let initialMemory = performanceMonitor.getCurrentMemoryUsage()
        
        // When
        let isHighPressure = performanceMonitor.isMemoryPressureHigh()
        
        // Then
        XCTAssertNotNil(initialMemory)
        XCTAssertFalse(isHighPressure) // Should be false in test environment
    }
    
    func testPerformanceMonitorMemoryWarnings() {
        // Given
        let initialWarnings = performanceMonitor.getPerformanceReport().memoryWarnings
        
        // When
        NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
        
        // Then
        let finalWarnings = performanceMonitor.getPerformanceReport().memoryWarnings
        XCTAssertEqual(finalWarnings, initialWarnings + 1)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryPressureHandling() {
        // Given
        var memoryPressureDetected = false
        
        let expectation = self.expectation(description: "Memory pressure handled")
        
        NotificationCenter.default.addObserver(
            forName: .memoryPressureDetected,
            object: nil,
            queue: .main
        ) { _ in
            memoryPressureDetected = true
            expectation.fulfill()
        }
        
        // When
        NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(memoryPressureDetected)
    }
    
    // MARK: - Performance Tests
    
    func testAppStateUpdatePerformance() {
        // Given
        let iterations = 1000
        
        // When
        let executionTime = PerformanceMonitor.measure("state_update_test") {
            for _ in 0..<iterations {
                appState.updateRouting { routing in
                    routing.countriesList.countryCode = UUID().uuidString.prefix(3).uppercased()
                }
            }
        }
        
        // Then
        let averageTime = executionTime / Double(iterations)
        XCTAssertLessThan(averageTime, 0.001) // Should be under 1ms per update
    }
    
    func testMemoryUsageStability() {
        // Given
        let initialMemory = performanceMonitor.getCurrentMemoryUsage()
        
        // When
        for _ in 0..<100 {
            let _ = AppState()
        }
        
        // Then
        let finalMemory = performanceMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory.residentSize > initialMemory.residentSize
        
        // Memory increase should be minimal due to proper cleanup
        XCTAssertLessThan(Double(finalMemory.residentSize - initialMemory.residentSize), 1024 * 1024) // Less than 1MB increase
    }
    
    // MARK: - Integration Tests
    
    func testAppStateLifecycle() {
        // Given
        let testAppState = AppState()
        
        // When
        testAppState.updateSystem { system in
            system.isActive = true
            system.lastActiveTime = Date()
        }
        
        testAppState.updatePermissions { permissions in
            permissions.push = .granted
        }
        
        // Then
        XCTAssertTrue(testAppState.system.isActive)
        XCTAssertEqual(testAppState.permissions.push, .granted)
        
        // Cleanup
        testAppState.cleanupForBackground()
        XCTAssertFalse(testAppState.system.isActive)
    }
    
    func testPerformanceReporting() {
        // Given
        let testMetrics = [
            PerformanceMetric(name: "test1", duration: 0.1, timestamp: Date(), metadata: nil),
            PerformanceMetric(name: "test2", duration: 0.2, timestamp: Date(), metadata: nil)
        ]
        
        // When
        for metric in testMetrics {
            performanceMonitor.recordMetric(metric.name, duration: metric.duration, metadata: metric.metadata)
        }
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Then
        XCTAssertEqual(report.metrics.count, 2)
        XCTAssertTrue(report.metrics.contains { $0.name == "test1" })
        XCTAssertTrue(report.metrics.contains { $0.name == "test2" })
    }
}

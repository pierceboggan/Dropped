//
//  AIWorkoutGeneratorTests.swift
//  DroppedTests
//
//  Unit tests for AIWorkoutGenerator service.
//
//  Tests verify:
//  - Model configuration is correctly set to gpt-4o-mini
//  - Service initialization works properly
//

import XCTest
@testable import Dropped

final class AIWorkoutGeneratorTests: XCTestCase {
    
    /// Test that the AIWorkoutGenerator is configured to use the correct OpenAI model
    func testModelConfiguration() throws {
        // Create an instance of AIWorkoutGenerator with a test API key
        let generator = AIWorkoutGenerator(apiKey: "test-api-key")
        
        // Use reflection to verify the model is set to gpt-4o-mini
        let mirror = Mirror(reflecting: generator)
        let modelProperty = mirror.children.first { $0.label == "model" }
        
        XCTAssertNotNil(modelProperty, "Model property should exist")
        if let modelValue = modelProperty?.value as? String {
            XCTAssertEqual(modelValue, "gpt-4o-mini", "Model should be configured to use gpt-4o-mini")
        } else {
            XCTFail("Model property should be a String")
        }
    }
    
    /// Test that AIWorkoutGenerator initializes with an API key
    func testInitialization() throws {
        let testApiKey = "test-api-key-12345"
        let generator = AIWorkoutGenerator(apiKey: testApiKey)
        
        // Verify the generator was created successfully
        XCTAssertNotNil(generator, "Generator should initialize successfully")
        
        // Use reflection to verify the API key is stored
        let mirror = Mirror(reflecting: generator)
        let apiKeyProperty = mirror.children.first { $0.label == "apiKey" }
        
        XCTAssertNotNil(apiKeyProperty, "API key property should exist")
        if let apiKeyValue = apiKeyProperty?.value as? String {
            XCTAssertEqual(apiKeyValue, testApiKey, "API key should be stored correctly")
        }
    }
}

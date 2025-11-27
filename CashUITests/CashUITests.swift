//
//  CashUITests.swift
//  CashUITests
//
//  Created by Michele Broggi on 25/11/25.
//

import XCTest

final class CashUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests
    
    @MainActor
    func testAppLaunches() throws {
        XCTAssertTrue(app.windows.count > 0)
    }
    
    @MainActor
    func testMainWindowExists() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
    }
    
    // MARK: - Sidebar Tests
    
    @MainActor
    func testSidebarExists() throws {
        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testNetWorthItemExists() throws {
        let netWorthLabel = app.staticTexts["Net Worth"]
        XCTAssertTrue(netWorthLabel.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testForecastItemExists() throws {
        let forecastLabel = app.staticTexts["Forecast"]
        XCTAssertTrue(forecastLabel.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testScheduledItemExists() throws {
        let scheduledLabel = app.staticTexts["Scheduled"]
        XCTAssertTrue(scheduledLabel.waitForExistence(timeout: 5))
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNavigateToNetWorth() throws {
        let netWorthLabel = app.staticTexts["Net Worth"]
        if netWorthLabel.waitForExistence(timeout: 5) {
            netWorthLabel.click()
            
            let netWorthTitle = app.staticTexts["Net Worth"].firstMatch
            XCTAssertTrue(netWorthTitle.exists)
        }
    }
    
    @MainActor
    func testNavigateToForecast() throws {
        let forecastLabel = app.staticTexts["Forecast"]
        if forecastLabel.waitForExistence(timeout: 5) {
            forecastLabel.click()
            
            let segmentedControl = app.segmentedControls.firstMatch
            XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3))
        }
    }
    
    @MainActor
    func testNavigateToScheduled() throws {
        let scheduledLabel = app.staticTexts["Scheduled"]
        if scheduledLabel.waitForExistence(timeout: 5) {
            scheduledLabel.click()
            
            let scheduledTitle = app.staticTexts["Scheduled Transactions"]
            XCTAssertTrue(scheduledTitle.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Menu Tests
    
    @MainActor
    func testFileMenuExists() throws {
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.exists)
        
        let fileMenu = menuBar.menuBarItems["File"]
        XCTAssertTrue(fileMenu.exists)
    }
    
    // MARK: - Forecast View Tests
    
    @MainActor
    func testForecastPeriodSelector() throws {
        let forecastLabel = app.staticTexts["Forecast"]
        guard forecastLabel.waitForExistence(timeout: 5) else {
            XCTFail("Forecast not found in sidebar")
            return
        }
        forecastLabel.click()
        
        let segmentedControl = app.segmentedControls.firstMatch
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3))
    }
    
    @MainActor
    func testForecastSummaryCards() throws {
        let forecastLabel = app.staticTexts["Forecast"]
        guard forecastLabel.waitForExistence(timeout: 5) else {
            XCTFail("Forecast not found in sidebar")
            return
        }
        forecastLabel.click()
        
        let currentBalanceLabel = app.staticTexts["Current Balance"]
        let projectedBalanceLabel = app.staticTexts["Projected Balance"]
        
        XCTAssertTrue(currentBalanceLabel.waitForExistence(timeout: 3))
        XCTAssertTrue(projectedBalanceLabel.waitForExistence(timeout: 3))
    }
    
    // MARK: - Keyboard Shortcut Tests
    
    @MainActor
    func testCmdNOpensDialog() throws {
        app.typeKey("n", modifierFlags: .command)
        
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        
        let cancelButton = sheet.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.click()
        } else {
            app.typeKey(.escape, modifierFlags: [])
        }
    }
}

// MARK: - Scheduled Transactions UI Tests

final class ScheduledTransactionsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testScheduledViewShowsEmptyState() throws {
        let scheduledLabel = app.staticTexts["Scheduled"]
        guard scheduledLabel.waitForExistence(timeout: 5) else {
            XCTFail("Scheduled not found in sidebar")
            return
        }
        scheduledLabel.click()
        
        let noScheduledLabel = app.staticTexts["No scheduled transactions"]
        let addButton = app.buttons["Add"]
        
        XCTAssertTrue(noScheduledLabel.waitForExistence(timeout: 3) || addButton.waitForExistence(timeout: 3))
    }
    
    @MainActor
    func testAddScheduledTransactionButton() throws {
        let scheduledLabel = app.staticTexts["Scheduled"]
        guard scheduledLabel.waitForExistence(timeout: 5) else {
            XCTFail("Scheduled not found in sidebar")
            return
        }
        scheduledLabel.click()
        
        let addButton = app.buttons["Add"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.click()
            
            let sheet = app.sheets.firstMatch
            XCTAssertTrue(sheet.waitForExistence(timeout: 3))
            
            let cancelButton = sheet.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.click()
            }
        }
    }
}

// MARK: - Account UI Tests

final class AccountUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testAddAccountDialog() throws {
        let netWorthLabel = app.staticTexts["Net Worth"]
        if netWorthLabel.waitForExistence(timeout: 5) {
            netWorthLabel.click()
        }
        
        app.typeKey("n", modifierFlags: .command)
        
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        
        let cancelButton = sheet.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.click()
        }
    }
}

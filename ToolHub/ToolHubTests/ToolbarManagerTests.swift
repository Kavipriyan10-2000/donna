import XCTest
@testable import ToolHub

final class ToolbarManagerTests: XCTestCase {
    
    var toolbarManager: ToolbarManager!
    
    override func setUp() {
        super.setUp()
        toolbarManager = ToolbarManager.shared
    }
    
    override func tearDown() {
        toolbarManager.clearToolbar()
        super.tearDown()
    }
    
    func testToolbarItemCreation() {
        let item = ToolbarItem(
            id: "test",
            type: .button,
            label: "Test Button",
            icon: "star",
            action: "testAction",
            options: nil,
            shortcut: nil,
            isEnabled: true
        )
        
        XCTAssertEqual(item.id, "test")
        XCTAssertEqual(item.type, .button)
        XCTAssertEqual(item.label, "Test Button")
        XCTAssertEqual(item.icon, "star")
        XCTAssertEqual(item.action, "testAction")
        XCTAssertTrue(item.isEnabled)
    }
    
    func testToolbarItemEquality() {
        let item1 = ToolbarItem(
            id: "test",
            type: .button,
            label: "Test",
            icon: nil,
            action: "action",
            options: nil,
            shortcut: nil,
            isEnabled: true
        )
        
        let item2 = ToolbarItem(
            id: "test",
            type: .dropdown,
            label: "Different",
            icon: nil,
            action: "different",
            options: ["option"],
            shortcut: nil,
            isEnabled: false
        )
        
        // Items with same ID should be equal
        XCTAssertEqual(item1, item2)
    }
    
    func testToolbarItemTypes() {
        let button = ToolbarItem(
            id: "1",
            type: .button,
            label: "Button",
            icon: nil,
            action: "",
            options: nil,
            shortcut: nil,
            isEnabled: true
        )
        
        let dropdown = ToolbarItem(
            id: "2",
            type: .dropdown,
            label: "Dropdown",
            icon: nil,
            action: "",
            options: ["A", "B"],
            shortcut: nil,
            isEnabled: true
        )
        
        let search = ToolbarItem(
            id: "3",
            type: .search,
            label: "Search",
            icon: nil,
            action: "",
            options: nil,
            shortcut: nil,
            isEnabled: true
        )
        
        let toggle = ToolbarItem(
            id: "4",
            type: .toggle,
            label: "Toggle",
            icon: nil,
            action: "",
            options: nil,
            shortcut: nil,
            isEnabled: true
        )
        
        XCTAssertEqual(button.type, .button)
        XCTAssertEqual(dropdown.type, .dropdown)
        XCTAssertEqual(search.type, .search)
        XCTAssertEqual(toggle.type, .toggle)
    }
}

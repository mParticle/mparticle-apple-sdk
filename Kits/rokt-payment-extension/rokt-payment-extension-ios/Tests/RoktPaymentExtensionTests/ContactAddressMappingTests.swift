import Contacts
import PassKit
import XCTest
@testable import RoktPaymentExtension

final class ContactAddressMappingTests: XCTestCase {

    func testMapWithFullContact() {
        let contact = PKContact()
        let nameComponents = PersonNameComponents()
        var name = nameComponents
        name.givenName = "Jane"
        name.familyName = "Smith"
        contact.name = name
        contact.emailAddress = "jane@example.com"

        let postal = CNMutablePostalAddress()
        postal.street = "42 Main St"
        postal.city = "New York"
        postal.state = "NY"
        postal.postalCode = "10001"
        postal.isoCountryCode = "US"
        contact.postalAddress = postal

        let address = ContactAddressMapping.map(from: contact)

        XCTAssertEqual(address.name, "Jane Smith")
        XCTAssertEqual(address.email, "jane@example.com")
        XCTAssertEqual(address.addressLine1, "42 Main St")
        XCTAssertEqual(address.city, "New York")
        XCTAssertEqual(address.state, "NY")
        XCTAssertEqual(address.postalCode, "10001")
        XCTAssertEqual(address.country, "US")
    }

    func testMapWithNilPostalAddress() {
        let contact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "John"
        name.familyName = "Doe"
        contact.name = name
        contact.emailAddress = "john@example.com"
        // postalAddress is nil by default

        let address = ContactAddressMapping.map(from: contact)

        XCTAssertEqual(address.name, "John Doe")
        XCTAssertEqual(address.email, "john@example.com")
        XCTAssertNil(address.addressLine1)
        XCTAssertNil(address.city)
        XCTAssertNil(address.state)
        XCTAssertNil(address.postalCode)
        XCTAssertNil(address.country)
    }

    func testMapWithNilName() {
        let contact = PKContact()
        // name is nil by default
        contact.emailAddress = "anon@example.com"

        let postal = CNMutablePostalAddress()
        postal.city = "Sydney"
        postal.isoCountryCode = "AU"
        contact.postalAddress = postal

        let address = ContactAddressMapping.map(from: contact)

        XCTAssertEqual(address.name, "")
        XCTAssertEqual(address.email, "anon@example.com")
        XCTAssertEqual(address.city, "Sydney")
        XCTAssertEqual(address.country, "AU")
    }

    func testMapWithOnlyGivenName() {
        let contact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "Madonna"
        contact.name = name

        let address = ContactAddressMapping.map(from: contact)

        XCTAssertEqual(address.name, "Madonna")
    }

    func testMapWithNilEmail() {
        let contact = PKContact()
        // emailAddress is nil by default

        let address = ContactAddressMapping.map(from: contact)

        XCTAssertEqual(address.email, "")
    }
}

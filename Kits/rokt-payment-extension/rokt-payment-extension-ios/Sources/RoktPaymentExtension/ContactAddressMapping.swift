import Contacts
import PassKit
import RoktContracts

enum ContactAddressMapping {
    static func map(from contact: PKContact) -> ContactAddress {
        let name = [contact.name?.givenName, contact.name?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        return ContactAddress(
            name: name,
            email: contact.emailAddress.flatMap { $0 as String? } ?? "",
            addressLine1: contact.postalAddress?.street,
            city: contact.postalAddress?.city,
            state: contact.postalAddress?.state,
            postalCode: contact.postalAddress?.postalCode,
            country: contact.postalAddress?.isoCountryCode
        )
    }
}

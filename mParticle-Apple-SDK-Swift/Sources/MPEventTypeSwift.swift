/// Event Types
@objc
public enum MPEventTypeSwift: UInt {
    /** Use for navigation related events */
    case navigation = 1
    /** Use for location related events */
    case location = 2
    /** Use for search related events */
    case search = 3
    /** Use for transaction related events */
    case transaction = 4
    /** Use for user content related events */
    case userContent = 5
    /** Use for user preference related events */
    case userPreference = 6
    /** Use for social related events */
    case social = 7
    /** Use for other types of events not contained in this enum */
    case other = 8
    /** Internal. Used when an event is related to or sourced from the Media SDK */
    case media = 9
    /** Internal. Used when a product is added to the cart */
    case addToCart = 10
    /** Internal. Used when a product is removed from the cart */
    case removeFromCart = 11
    /** Internal. Used when the cart goes to checkout */
    case checkout = 12
    /** Internal. Used when the cart goes to checkout with options */
    case checkoutOption = 13
    /** Internal. Used when a product is clicked */
    case click = 14
    /** Internal. Used when user views the details of a product */
    case viewDetail = 15
    /** Internal. Used when a product is purchased */
    case purchase = 16
    /** Internal. Used when a product refunded */
    case refund = 17
    /** Internal. Used when a promotion is displayed */
    case promotionView = 18
    /** Internal. Used when a promotion is clicked */
    case promotionClick = 19
    /** Internal. Used when a product is added to the wishlist */
    case addToWishlist = 20
    /** Internal. Used when a product is removed from the wishlist */
    case removeFromWishlist = 21
    /** Internal. Used when a product is displayed in a promotion */
    case impression = 22
};

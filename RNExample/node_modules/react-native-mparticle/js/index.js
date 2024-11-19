'use strict'

import { NativeModules } from 'react-native'

// ******** Constants ********

const EventType = {
  Navigation: 1,
  Location: 2,
  Search: 3,
  Transaction: 4,
  UserContent: 5,
  UserPreference: 6,
  Social: 7,
  Other: 8,
  Media: 9
}

const UserAttributeType = {
  FirstName: '$FirstName',
  LastName: '$LastName',
  Address: '$Address',
  State: '$State',
  City: '$City',
  Zipcode: '$Zip',
  Country: '$Country',
  Age: '$Age',
  Gender: '$Gender',
  MobileNumber: '$Mobile'
}

const UserIdentityType = {
  Other: 0,
  CustomerId: 1,
  Facebook: 2,
  Twitter: 3,
  Google: 4,
  Microsoft: 5,
  Yahoo: 6,
  Email: 7,
  Alias: 8,
  FacebookCustomAudienceId: 9,
  Other2: 10,
  Other3: 11,
  Other4: 12,
  Other5: 13,
  Other6: 14,
  Other7: 15,
  Other8: 16,
  Other9: 17,
  Other10: 18,
  MobileNumber: 19,
  PhoneNumber2: 20,
  PhoneNumber3: 21,
  IOSAdvertiserId: 22,
  IOSVendorId: 23,
  PushToken: 24,
  DeviceApplicationStamp: 25
}

const ProductActionType = {
  AddToCart: 1,
  RemoveFromCart: 2,
  Checkout: 3,
  CheckoutOption: 4,
  Click: 5,
  ViewDetail: 6,
  Purchase: 7,
  Refund: 8,
  AddToWishlist: 9,
  RemoveFromWishlist: 10
}

const PromotionActionType = {
  View: 0,
  Click: 1
}

const ATTAuthStatus = {
  NotDetermined: 0,
  Restricted: 1,
  Denied: 2,
  Authorized: 3
}

// ******** Main API ********

const upload = () => {
  NativeModules.MParticle.upload()
}

const setUploadInterval = (uploadInterval) => {
  NativeModules.MParticle.setUploadInterval(uploadInterval)
}

const logEvent = (eventName, type = EventType.Other, attributes = null) => {
  NativeModules.MParticle.logEvent(eventName, type, attributes)
}

const logMPEvent = (event) => {
  NativeModules.MParticle.logMPEvent(event)
}

const logCommerceEvent = (commerceEvent) => {
  NativeModules.MParticle.logCommerceEvent(commerceEvent)
}

const logScreenEvent = (screenName, attributes = null, shouldUploadEvent = true) => {
  NativeModules.MParticle.logScreenEvent(screenName, attributes, shouldUploadEvent)
}

// Use ATTAuthStatus constants for status
const setATTStatus = (status) => {
  NativeModules.MParticle.setATTStatus(status)
}

const setATTStatusWithCustomTimestamp = (status, timestamp) => {
  NativeModules.MParticle.setATTStatus(status, timestamp)
}

const setOptOut = (optOut) => {
  NativeModules.MParticle.setOptOut(optOut)
}

const getOptOut = (completion) => {
  NativeModules.MParticle.getOptOut(completion)
}

const addGDPRConsentState = (newConsentState, purpose) => {
  NativeModules.MParticle.addGDPRConsentState(newConsentState, purpose)
}

const removeGDPRConsentStateWithPurpose = (purpose) => {
  NativeModules.MParticle.removeGDPRConsentStateWithPurpose(purpose)
}

const setCCPAConsentState = (newConsentState) => {
  NativeModules.MParticle.setCCPAConsentState(newConsentState)
}

const removeCCPAConsentState = () => {
  NativeModules.MParticle.removeCCPAConsentState()
}

const isKitActive = (kitId, completion) => {
  NativeModules.MParticle.isKitActive(kitId, completion)
}

const getAttributions = (completion) => {
  NativeModules.MParticle.getAttributions(completion)
}

const logPushRegistration = (registrationField1, registrationField2) => {
  NativeModules.MParticle.logPushRegistration(registrationField1, registrationField2)
}

const getSession = (completion) => {
  NativeModules.MParticle.getSession(completion)
}

const setLocation = (latitude, longitude) => {
  NativeModules.MParticle.setLocation(latitude, longitude)
}

// ******** Identity ********
class User {
  constructor (userId) {
    this.userId = userId
  }

  getMpid () {
    return this.userId
  }

  setUserAttribute (key, value) {
    if (value && value.constructor === Array) {
      NativeModules.MParticle.setUserAttributeArray(this.userId, key, value)
    } else {
      NativeModules.MParticle.setUserAttribute(this.userId, key, value)
    }
  }

  setUserAttributeArray (key, value) {
    NativeModules.MParticle.setUserAttributeArray(this.userId, key, value)
  }

  getUserAttributes (completion) {
    NativeModules.MParticle.getUserAttributes(this.userId, (error, userAttributes) => {
      if (error) {
        console.log(error.stack)
      }
      completion(userAttributes)
    })
  }

  setUserTag (value) {
    NativeModules.MParticle.setUserTag(this.userId, value)
  }

  incrementUserAttribute (key, value) {
    NativeModules.MParticle.incrementUserAttribute(this.userId, key, value)
  }

  removeUserAttribute (key) {
    NativeModules.MParticle.removeUserAttribute(this.userId, key)
  }

  getUserIdentities (completion) {
    NativeModules.MParticle.getUserIdentities(this.userId, (error, userIdentities) => {
      if (error) {
        console.log(error.stack)
      }
      completion(userIdentities)
    })
  }

  getFirstSeen (completion) {
    NativeModules.MParticle.getFirstSeen(this.userId, completion)
  }

  getLastSeen (completion) {
    NativeModules.MParticle.getLastSeen(this.userId, completion)
  }
}

class IdentityRequest {

  setEmail (email) {
    this[UserIdentityType.Email] = email
    return this
  }

  setCustomerID (customerId) {
    this[UserIdentityType.CustomerId] = customerId
    return this
  }

  setUserIdentity (userIdentity, identityType) {
    this[identityType] = userIdentity
    return this
  }

  setOnUserAlias (onUserAlias) {
    console.log("Warning: deprecated method 'setUserAlias(onUserAlias)', will be removed in future releases")
  }
}

class Identity {

  static getCurrentUser (completion) {
    NativeModules.MParticle.getCurrentUserWithCompletion((error, userId) => {
      if (error) {
        console.log(error.stack)
      }
      var currentUser = new User(userId)
      completion(currentUser)
    })
  }

  static identify (IdentityRequest, completion) {
    NativeModules.MParticle.identify(IdentityRequest, (error, userId, previousUserId) => {
      if (error == null || error === undefined) {
        completion(error, userId, previousUserId)
      } else {
        var parsedError = new MParticleError(error)
        completion(parsedError, userId, previousUserId)
      }
    })
  }

  static login (IdentityRequest, completion) {
    NativeModules.MParticle.login(IdentityRequest, (error, userId, previousUserId) => {
      if (error == null || error === undefined) {
        completion(error, userId, previousUserId)
      } else {
        var parsedError = new MParticleError(error)
        completion(parsedError, userId, previousUserId)
      }
    })
  }

  static logout (IdentityRequest, completion) {
    NativeModules.MParticle.logout(IdentityRequest, (error, userId, previousUserId) => {
      if (error == null || error === undefined) {
        completion(error, userId, previousUserId)
      } else {
        var parsedError = new MParticleError(error)
        completion(parsedError, userId, previousUserId)
      }
    })
  }

  static modify (IdentityRequest, completion) {
    NativeModules.MParticle.modify(IdentityRequest, (error, userId, previousUserId) => {
      if (error == null || error === undefined) {
        completion(error, userId, previousUserId)
      } else {
        var parsedError = new MParticleError(error)
        completion(parsedError, userId, previousUserId)
      }
    })
  }

  static aliasUsers (AliasRequest, completion) {
    NativeModules.MParticle.aliasUsers(AliasRequest, completion)
  }

}

// ******** Commerce ********

class Impression {
  constructor (impressionListName, products) {
    this.impressionListName = impressionListName
    this.products = products
  }
}

class Promotion {
  constructor (id, name, creative, position) {
    this.id = id
    this.name = name
    this.creative = creative
    this.position = position
  }
}

class AliasRequest {

  sourceMpid (mpid) {
    this.sourceMpid = mpid
    return this
  }

  destinationMpid (mpid) {
    this.destinationMpid = mpid
    return this
  }

  endTime (mpid) {
    this.endTime = mpid
    return this
  }

  startTime (mpid) {
    this.startTime = mpid
    return this
  }
}

class TransactionAttributes {
  constructor (transactionId) {
    this.transactionId = transactionId
  }

  setAffiliation (affiliation) {
    this.affiliation = affiliation
    return this
  }

  setRevenue (revenue) {
    this.revenue = typeof revenue === 'string' ? parseFloat(revenue) : revenue
    return this
  }

  setShipping (shipping) {
    this.shipping = typeof shipping === 'string' ? parseFloat(shipping) : shipping
    return this
  }

  setTax (tax) {
    this.tax = typeof tax === 'string' ? parseFloat(tax) : tax
    return this
  }

  setCouponCode (couponCode) {
    this.couponCode = couponCode
    return this
  }
}

class Product {
  constructor (name, sku, price, quantity = 1) {
    this.name = name
    this.sku = sku
    this.price = price
    this.quantity = quantity
  }

  setBrand (brand) {
    this.brand = brand
    return this
  }

  setCouponCode (couponCode) {
    this.couponCode = couponCode
    return this
  }

  setPosition (position) {
    this.position = position
    return this
  }

  setCategory (category) {
    this.category = category
    return this
  }

  setVariant (variant) {
    this.variant = variant
    return this
  }

  setCustomAttributes (customAttributes) {
    this.customAttributes = customAttributes
    return this
  }
}

class GDPRConsent {

  constructor (consented, doc, timestamp, location, hardwareId) {
    this.consented = consented
    this.document = doc
    this.timestamp = timestamp
    this.location = location
    this.hardwareId = hardwareId
  }

  setConsented (consented) {
    this.consented = consented
    return this
  }

  setDocument (doc) {
    this.document = doc
    return this
  }

  setTimestamp (timestamp) {
    this.timestamp = timestamp
    return this
  }

  setLocation (location) {
    this.location = location
    return this
  }

  setHardwareId (hardwareId) {
    this.hardwareId = hardwareId
    return this
  }
}

class CCPAConsent {

  constructor (consented, doc, timestamp, location, hardwareId) {
    this.consented = consented
    this.document = doc
    this.timestamp = timestamp
    this.location = location
    this.hardwareId = hardwareId
  }

  setConsented (consented) {
    this.consented = consented
    return this
  }

  setDocument (doc) {
    this.document = doc
    return this
  }

  setTimestamp (timestamp) {
    this.timestamp = timestamp
    return this
  }

  setLocation (location) {
    this.location = location
    return this
  }

  setHardwareId (hardwareId) {
    this.hardwareId = hardwareId
    return this
  }
}

class CommerceEvent {

  static createProductActionEvent (productActionType, products, transactionAttributes = {}) {
    return new CommerceEvent()
                    .setProductActionType(productActionType)
                    .setProducts(products)
                    .setTransactionAttributes(transactionAttributes)
  }

  static createPromotionEvent (promotionActionType, promotions) {
    return new CommerceEvent()
                    .setPromotionActionType(promotionActionType)
                    .setPromotions(promotions)
  }

  static createImpressionEvent (impressions) {
    return new CommerceEvent()
                    .setImpressions(impressions)
  }

  setTransactionAttributes (transactionAttributes) {
    this.transactionAttributes = transactionAttributes
    return this
  }

  setProductActionType (productActionType) {
    this.productActionType = productActionType
    return this
  }

  setPromotionActionType (promotionActionType) {
    this.promotionActionType = promotionActionType
    return this
  }

  setProducts (products) {
    this.products = products
    return this
  }

  setPromotions (promotions) {
    this.promotions = promotions
    return this
  }

  setImpressions (impressions) {
    this.impressions = impressions
    return this
  }

  setScreenName (screenName) {
    this.screenName = screenName
    return this
  }

  setCurrency (currency) {
    this.currency = currency
    return this
  }

  setCustomAttributes (customAttributes) {
    this.customAttributes = customAttributes
    return this
  }

  setCheckoutOptions (checkoutOptions) {
    this.checkoutOptions = checkoutOptions
    return this
  }

  setProductActionListName (productActionListName) {
    this.productActionListName = productActionListName
    return this
  }

  setProductActionListSource (productActionListSource) {
    this.productActionListSource = productActionListSource
    return this
  }

  setCheckoutStep (checkoutStep) {
    this.checkoutStep = checkoutStep
    return this
  }

  setNonInteractive (nonInteractive) {
    this.nonInteractive = nonInteractive
    return this
  }

  setShouldUploadEvent (shouldUploadEvent) {
    this.shouldUploadEvent = shouldUploadEvent
    return this
  }
}

class Event {

  setCategory (category) {
    this.category = category
    return this
  }

  setDuration (duration) {
    this.duration = duration
    return this
  }

  setEndTime (endTime) {
    this.endTime = endTime
    return this
  }

  setInfo (info) {
    this.info = info
    return this
  }

  setName (name) {
    this.name = name
    return this
  }

  setStartTime (startTime) {
    this.startTime = startTime
    return this
  }

  setType (type) {
    this.type = type
    return this
  }

  setShouldUploadEvent (shouldUploadEvent) {
    this.shouldUploadEvent = shouldUploadEvent
    return this
  }

  setCustomFlags (customFlags) {
    this.customFlags = customFlags
    return this
  }
}

class MParticleError {
  constructor (errorResponse) {
    this.httpCode = errorResponse.httpCode

    this.responseCode = errorResponse.responseCode

    this.message = errorResponse.message

    this.mpid = errorResponse.mpid

    this.errors = errorResponse.errors
  }
}

// ******** Exports ********

const MParticle = {

  EventType,            // Constants
  UserIdentityType,
  UserAttributeType,
  ProductActionType,
  PromotionActionType,
  ATTAuthStatus,

  Product,              // Classes
  Impression,
  Promotion,
  CommerceEvent,
  TransactionAttributes,
  IdentityRequest,
  AliasRequest,
  Identity,
  User,
  Event,
  MParticleError,
  GDPRConsent,
  CCPAConsent,

  upload,             // Methods
  setUploadInterval,
  logEvent,
  logMPEvent,
  logCommerceEvent,
  logScreenEvent,
  setATTStatus,
  setATTStatusWithCustomTimestamp,
  setOptOut,
  getOptOut,
  addGDPRConsentState,
  removeGDPRConsentStateWithPurpose,
  setCCPAConsentState,
  removeCCPAConsentState,
  isKitActive,
  getAttributions,
  logPushRegistration,
  getSession,
  setLocation
}

export default MParticle

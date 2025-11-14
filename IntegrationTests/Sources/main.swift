import Foundation
import mParticle_Apple_SDK


var options = MParticleOptions(
    key: "", // Put your key
    secret: "" // Put your secret
)

var identityRequest = MPIdentityApiRequest.withEmptyUser()
identityRequest.email = "foo@example.com";
identityRequest.customerId = "123456";
options.identifyRequest = identityRequest;

options.onIdentifyComplete = { apiResult, error in
    if let apiResult {
        apiResult.user.setUserAttribute("example attribute key", value: "example attribute value")
    }
}
options.logLevel = .verbose

var networkOptions = MPNetworkOptions()
networkOptions.configHost = "127.0.0.1"; // config2.mparticle.com
networkOptions.eventsHost = "127.0.0.1"; // nativesdks.mparticle.com
networkOptions.identityHost = "127.0.0.1"; // identity.mparticle.com
networkOptions.pinningDisabled = true;

options.networkOptions = networkOptions;
let mparticle = MParticle.sharedInstance()
mparticle.start(with: options)

sleep(1)

mparticle.logEvent("Simple Event Name", eventType: .other, eventInfo: ["SimpleKey": "SimpleValue"])

sleep(7)

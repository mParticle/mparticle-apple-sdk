//
//  main.swift
//  IntegrationTests
//
//  Created by Denis Chilik on 11/4/25.
//

import Foundation
import mParticle_Apple_SDK


var options = MParticleOptions(
    key: "us1-e5145d11865db44eb24cd5a9f194d654",
    secret: "4g66BN4w-1XNO1BkIXf2sVKlhkO_ADGtHQLxsr1ouoBCt1xUegQvGN39pm6u8zi8"
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

sleep(10)

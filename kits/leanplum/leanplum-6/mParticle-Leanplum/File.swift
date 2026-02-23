// NOTE: This file only exists to fix compatibility with Carthage. Without any Swift files,
//       Xcode will fail to link to the Swift frameworks. This doesn't affect projects using
//       SPM or Cocoapods, as the Swift files in the Leanplum framework are compiled with
//       the project. With Carthage, since the framework is compiled separately, Xcode
//       doesn't recognize that it needs to link to Swift (this appears to be an Xcode bug).
import Foundation

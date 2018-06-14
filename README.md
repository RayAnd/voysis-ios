WARNING: This is a beta release of the Voysis iOS SDK.

Voysis iOS Swift SDK
=====================


This document provides a brief overview of the Voysis iOS SDK.
This is an iOS library that facilitates sending voice
queries to a Voysis instance. The SDK streams audio from the device microphone
to the Voysis backend servers when called by the client application.


Documentation
-------------


The full documentation for the voysis api can be found here: [Voysis Developer Documentation](https://developers.voysis.com/docs)


Requirements
-------------


- iOS 8.0+
- Xcode 9.0+
- Swift 4.0+


Overview
-------------


The `Voysis.Service` class is the main interface used to process voice recognition requests.
It is accessed via the static `Voysis.ServiceProvider.make(config: Config(url : "http://ADD-URL.com/websocketapi"))` method.
The sdk communicates to the network using a Websocket connection accomplished using the `Starscream.framework`.
The iOS core library, `Audio Toolbox Audio Queue Services` is used for recording the users voice.


Config
-------------

To create a service instance you need to provide config information at construction time.
The config file is comprised of several fields.

- **url** - *URL:* This is the endpoint that network requests will be executed against.
The url is provided when your Voysis service is delivered. To sign up for a Voysis service visit our [homepage](https://voysis.com/)

- **refreshToken** - *String:* The refresh token is used for authenticating unique users and for refreshing session tokens.
This is all taken care of from within the library once the `refreshToken` is provided.
For information on how to generate a refresh token see [here](https://developers.voysis.com/docs/authorization#section-introduction)

- **userId** - *String?:* This is an optional UUID used for identifying users to improve query results over time. See [here](https://developers.voysis.com/docs/general-concepts#section-properties) for more details.



Context - Entities
-------------


One of the features of using the Voysis service is that different json response types can be returned depending on what service you're subscribed to.
The json objects which vary in type are `Context` and `Entities`. see [Api Docs](https://developers.voysis.com/docs/apis-1#section-stream-audio-data) for information.
In order to facilitate this in the sdk and avail of the swift 4.0 `Codable` serialization protocol, the object structure for `Context` and `Entities`
must be setup by the user and added as generic parameters in the success callback. See the [demo application](https://github.com/voysis/voysis-ios/tree/master/example/VoysisDemo/VoysisDemo) and [Usage](https://github.com/voysis/voysis-ios/blob/master/README.md#usage) below for an example of this in action.


Usage
-------------


- The first step is to create a `Voysis.Servie` instance.
```swift
let voysis = Voysis.ServiceProvider.Make(config: Config(url: URL(string: "//INCLUDE-URL-HERE")!, refreshToken: "REFRESH-TOKEN"))
```


- Next: to make a request, call service.startAudioQuery with the mandatory Callback parameter and optional voysis Context (See context section below for details).
```swift
class ViewController: UIViewController, Callback {
    ...
    @IBAction func buttonClicked(_ sender: Any) {
        voysis.startAudioQuery(context: self.context, callback: self)
    }

    func success(response: StreamResponse<CommerceContext, CommerceEntities>) {
        // Mandatory: called when final response returned from server.
    }

    func failure(error: VoysisError) {
        // Mandatory: called when any error occurs
    }

    func recordingStarted() {
        //Optional: called when microphone begins recording.
    }

    func queryResponse(queryResponse: QueryResponse) {
        //Optional: called when successful connection is made to the server.
    }

    func recordingFinished(reason: FinishedReason) {
        //Optional: called when recording stops. Includes finishedReason enum.
    }

    func audioData(data: Data) {
        //Optional: returns audio data to the user that can be used generating for dynamic animations, analytics etc.
    }
}
```

Integration - Carthage
-------------

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to add and install.

To integrate the VoysisSdk into your Xcode project using Carthage, specify it in your Cartfile:

`github "/voysis/voysis-ios"`

- Once added, run `carthage update --no-use-binaries --platform iOS` from within your projects root directory.
- Next, from within xCode, in the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- Click `Add Other`
- Navigate to {{YOUR_PROJECT}}/Carthage/Build/iOS and click the `Voysis.framework` and `Starscream.framework`

Manual Integration - Embedded Framework
-------------


Note: This project requires [Carthage](https://github.com/Carthage/Carthage) to download the [Starscream](https://github.com/daltoniam/Starscream) Websocket dependency.

Adding Voysis Sdk
- First clone the project. Next, open the new `Voysis` folder, and drag the `Voysis.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see the `Voysis.framework` nested inside a `Products` folder.
- Select the `Voysis.framework` for iOS.

Adding Starscream
- From within the Voysis directory run `carthage update --no-use-binaries --platform iOS` to download the Starscream.framework.
- Again Click on the `+` button under the "Embedded Binaries" section.
- Click `Add Other`.
- Navigate to Voysis/Carthage/Build/iOS and click the Starscream.framework.

IMPORTANT NOTE
-------------


As of iOS10 you will need to include `NSMicrophoneUsageDescription` in the application Info.plist.


# Plivo Voice Quickstart for iOS



![plivo-iOSsdk-2.0-example](ReadMeImages/app.png)


The Plivo iOS SDK v2 allows you to make outgoing and receive incoming calls in your iOS application.

Supports Pushkit and Callkit. Eliminates the need for persistent connections to recieve incoming calls.

Compatible with iOS version 8 and above.

Plivo iOS SDK now supports IPv6 networks. Users can make and receive calls when their device is connected to a network that uses IPv4, IPv6, or both versions of the protocol.

To get started with the quickstart application follow these steps. Steps 1-3 will enable the application to make a call. The remaining steps 4-5 will enable the application to receive incoming calls in the form of push notifications using Apple’s VoIP Service.

1. [Install the PlivoVoiceKit framework using Cocoapods](#bullet1)

2. [Create Endpoints](#bullet2)

3. [Register and Unregister Endpoint](#bullet3)

4. [Run the app](#bullet4)

5. [Plivo iOS SDK V2 with Push Kit integration](#bullet5)

6. [Making an outgoing call](#bullet6)

7. [Receive an incoming call](#bullet7)


### <a name="bullet1"></a>1. Install the PlivoVoiceKit framework using Cocoapods

It's easy to install the Voice framework if you manage your dependencies using Cocoapods. Simply add the following to your Podfile:


pod 'PlivoVoiceKit'


[SDK Reference](https://www.plivo.com/docs/sdk/ios/v2/reference) - More documentation related to the Voice iOS SDK

### <a name="bullet2"></a>2. Create Endpoints

Signup and create endpoints with Plivo using below link

[Plivo Dashboard](https://manage.plivo.com/accounts/login/)

### <a name="bullet3"></a>3. Rgister and Unregister Endpoints

Implement SIP register to Plivo Communication Server

To register with Plivo's SIP and Media server , use a valid sip uri account from plivo web console 
```
var endpoint: PlivoEndpoint = PlivoEndpoint(debug: true)

// To register with SIP Server
func login( withUserName userName: String, andPassword password: String) {
UtilClass.makeToastActivity()
endpoint.login(userName, andPassword: password)
}

//To unregister with SIP Server
func logout() {
endpoint.logout()
}
```
If the registration to an endpoint fails the following delegate gets called 
```
(void)onLoginFailedWithError:(NSError *)error;
```

### <a name="bullet4"></a>4. Run the app

Open `SwiftVoiceCallingApp.xcworkspace`. 

Build and run the app. 

Enter sip endpoint username and password. 

After successful login make VoiceCalls. 


### <a name="bullet5"></a>5. Plivo iOS SDK V2 with Push Kit integration

To enable Pushkit Integration in the SDK the registerToken and relayVoipPushNotification are implemented 
```
//Register pushkit token
func registerToken(_ token: Data) {
endpoint.registerToken(token)
}

//receive and pass on (information or a message)
func relayVoipPushNotification(_ pushdata: [AnyHashable: Any]) {
endpoint.relayVoipPushNotification(pushdata)
}
```
please refer to below link on Generating VoIP Certificate. 

[Generating VoIP Certificate](https://www.plivo.com/docs/sdk/ios/setting-up-push-credentials/)


### <a name="bullet6"></a>6. Making an outgoing call

Create PlivoOutgoingCall object , then make a call with destination and headers 
```
func call(withDest dest: String, andHeaders headers: [AnyHashable: Any], error: inout NSError?) -> PlivoOutgoing {
/* construct SIP URI , where kENDPOINTURL is a contant contaning domain name details*/
let sipUri: String = "sip:\(dest)\(kENDPOINTURL)"
/* create PlivoOutgoing object */
outCall = (endpoint.createOutgoingCall())!
/* do the call */
outCall?.call(sipUri, headers: headers, error: &error)
return outCall!
}

//To Configure Audio
func configureAudioSession() {
endpoint.configureAudioDevice()
}
```
configureAudioSession - use this callkit method to set up the AVAudioSession with desired configuration.

Make an outbound call

Calling this method on the PlivoOutgoing object with the SIP URI
would initiate an outbound call.
```
(void)call:(NSString *)sipURI error:(NSError **)error;
```

Make an outbound call with custom SIP headers

Calling this method on the PlivoOutgoing object with the SIP URI
would initiate an outbound call with custom SIP headers.
```
(void)call:(NSString *)sipURI headers:(NSDictionary *)headers error:(NSError **)error;
```


### <a name="bullet7"></a>7. Receive an incoming call

```
// MARK: PKPushRegistryDelegate
func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, forType type: PKPushType) {

if credentials.token.count == 0 {
print("VOIP token NULL")
return
}

// This method is used to register the device token for VOIP push notifications.
endpoint.registerToken(credentials.token)
}

//When the push arrives below delegate method will be called. 
func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {

if (type == PKPushType.voIP) {

DispatchQueue.main.async(execute: {() -> Void in
endpoint.relayVoipPushNotification(payload.dictionaryPayload)
})
}
}
```
PushInfo is the NSDictionary object forwarded by the apple push notification. This will enable the application to receive incoming calls even the app is not in foreground.


You are now ready to receive incoming calls. 

![plivo-iOSsdk-2.0-example](ReadMeImages/callkit.png)

License

MIT

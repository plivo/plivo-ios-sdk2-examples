**Plivo Voice Quickstart for iOS**


To get started with the quickstart application follow these steps. Steps 1-3 will enable the application to make a call. The remaining steps 4-6 will enable the application to receive incoming calls in the form of push notifications using Apple’s VoIP Service.

**Install the PlivoVoiceKit framework using Cocoapods**

**Create Endpoints**

**Run the app**

**Create a VoIP Service Certificate**

**Configure Xcode project settings for VoIP push notifications**

**Receive an incoming call**



**1. Install the PlivoVoiceKit framework using Cocoapods**

It's easy to install the Voice framework if you manage your dependencies using Cocoapods. Simply add the following to your Podfile:


    source 'https://github.com/cocoapods/specs'

    source 'https://github.com/plivo/cocoapod-specs'

    target 'TARGET_NAME' do
    use_frameworks!

    pod 'PlivoVoiceKit'
    end

**2. Create Endpoints**

    Signup and create endpoints with Plivo using below url

    https://manage.plivo.com/accounts/login/


**3. Run the app**

    Open ObjCVoiceCallingApp.xcworkspace or SwiftVoiceCallingApp.xcworkspace. Build and run the app. Enter sip endpoint username and password. After successful login make VoiceCalls. 


**4. Plivo iOS SDK V2 with Push Kit integration**

    The following section explains on how to receive incoming calls on the Plivo iOS SDK v2 using pushkit. Receiving an incoming call requires the following four steps:
     
     1. Enabling VoIP services in your application
     2. Creating the VoIP service certificate
     3. Creating a push credential (.p12 file) using the VoIP certificate
     4. Updating the information in the Plivo dashboard


      Let us see each of these steps in detail.

      1. Enable VoIP services in your application
        
        You can enable VoIP services from XCode. Select the “ Capabilities” tab and enable the following settings:
        a. Make sure “Push Notifications” and “Background Modes” are set to on.
        b. Within “Background Modes” enable both “Audio, AirPlay and Picture in Picture” and “Voice over IP” settings.

      2. Create VoIP Service Certificate
        
        Creating a VoIP service certificate requires two steps:
        a. Creating a certificate signing request (CSR)
        b. Creating the service certificate using the CSR
        
        Create a Certificate Signing Request(CSR)
            Certificate signing request (CSR) is a prerequisite for creating a certificate in the  iOS Dev Center . CSR can be generated using the following steps:
            
            a. Open Keychain access by selecting “Open Keychain access” in utilities folder. You can select that as shown in the image.

            b. Once Keychain access opens click on “Keychain Access” from the Menu bar and select the following:  Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority .
            c. Give your CSR a helpful descriptive name, such as iosplivoapp.certSigningRequest, and choose the location to save it on your hard drive, then click Save.

            d. Next, visit the  Apple Developer portal  and make sure that your App ID has the “Push Notifications” service enabled.
            e. Visit certificates section in  Apple Developer portal  upload .csr file and create certificate.

            f. Create a corresponding Provisioning Profile for your app ID and create an  Apple VoIP Services Certificate  for this app.


      3. Create a Push Credential with your VoIP Service Certificate
      
          Once you have generated the VoIP Services Certificate, you will need to update it in Plivo dashboard so that Plivo can send push notifications to your app on your behalf.
          a. Export your VoIP Service Certificate as a .p12 file from Keychain Access.

          You need not enter a password and create the .p12 file by clicking on OK.


      4. Updating the information in Plivo dashboard
      
            The certificate key and the private key need to be generated from the .p12 file. The files can be generated as follows.

            Create a Certificate Key

            Certificate key can be generated by running the following command in terminal
            openssl pkcs12 -in VOIP_SNS.p12 -nokeys -out cert.pem -nodes
            
            Create a Private Key
            
            Private key can be generated by running the following command in terminal
            openssl pkcs12 -in VOIP_SNS.p12 -nocerts -out key.pem -nodes

            The RSA key can be processed using this command.
            openssl rsa -in key.pem -out key.pem

            Updating information in Plivo dashboard
            
            From the output of the previous command, strip anything outside of "-----BEGIN CERTIFICATE-----" and "-----END CERTIFICATE-----" boundaries and outside of "-----BEGIN RSA PRIVATE KEY-----" and "-----END RSA PRIVATE KEY-----" boundaries.

            This text can be pasted into the UI that will be available in the Plivo Dashboard.

            Please make sure to select the ‘Sandbox’ mode in case you have generated a sandbox certificate (similar to development mode).

            The iOS application should register for Push Notifications and get the device token from APNS. This can be used with Plivo iOS SDK v2 using the following API.

**5. Configure Xcode project settings for push notifications**

      On the project’s Capabilities tab, enable “Push Notifications”, and enable both “Voice over IP” and “Audio, AirPlay and Picture in Picture” capabilities in the Background Modes


**6. Receive an incoming call**

    - (void)registerToken:(NSData*)token;

      This will enable the application to receive incoming calls even the app is not in foreground.

    - (void)relayVoipPushNotification:(NSDictionary *)pushInfo;

      PushInfo is the NSDictionary object forwarded by the apple push notification.

You are now ready to receive incoming calls. 

License

MIT

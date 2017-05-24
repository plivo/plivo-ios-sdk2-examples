
Process to upload iOS app to AppStore or TestFlight

1. Open project in Xcode

2. Go to General and change app version number. Change Intents version numner(If you are using any extensions for ex Siri extension)

3. There are 2 ways to upload app to AppStore

    a) Using Applicaiton Loader. Application Loader is always part of an Xcode install. 
    
        Create .ipa file:

        1. Select Product -> Archive -> Export -> Save for iOS app store Deployment -> export .ipa file

        2. Use the menu /Xcode/Open Developer Tool/Application Loader

        3. Login to Applicaiton Loader with iTunes Connect account and upload above .ipa file. It may take few mins to upload.

    b) Using Xcode
    
        Select Product -> Archive -> Upload to AppStore. It may take few mins to upload.

4. After few mins App will appear in iTunes connect account.

5. If you are Submitting the app to Test Flight 

    1. Select TestFlight Tab in iTunes Connect

    2. Add internal and external testers.

    3. Add an iOS build to test, add App’s Metadata(App name, Description, Screenshots, Privacy urls etc)

    4. Users will receive an email with TestFight installation link.

    5. Users have to install TestFlight app from the AppStore.

    5. Now users can install or update our app via TestFlight app.

6. If you are submitting the app to AppStore 

    1. Select AppStore Tab in iTunes Connect

    2. Add App’s Metadata(App name, Description, Screenshots, Privacy urls etc)

    3. Submit app to AppStore

    4. App will appear in Apple AppStore after few approval processes.

    
    

    


Please find below links for reference

1. https://www.raywenderlich.com/133121/testflight-tutorial-ios-beta-testing

2. https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/UploadingBinariesforanApp.html


    

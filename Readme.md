## Reveal iOS Jailbreak Tweak 
Reveal Loader dynamically loads libReveal.dylib (Reveal.app support) into iOS apps on jailbroken devices. Configuration is via the Reveal menu in Settings.app

Reveal is an OS X application that allows you to remotely introspect a running applications view hierarchy and edit various view properties. 

Generally you have to include their debugging framework in your application at build time in-order to perform debugging actions, however with this tweak installed this is no longer necessary. 

For more info see [revealapp.com](http://revealapp.com)


## How to Install
1) Follow the instructions here(https://hackinggate.com/2019/06/11/inspect-the-view-hierarchy-of-any-ios-apps-on-ios-12.html).
2) Swap out https://github.com/HackingGate/Reveal2Loader.git with https://github.com/divyeshmakwana96/Reveal3Loader.git

## How to Use
Open 'Settings > Reveal > Enabled Applications' and toggle the application or applications that you want to debug to on.

Launch the target application and it should appear inside Reveal.app on your Mac. 

(You will likely need to quit and relaunch the target application)

Spil SDK (tvOS)
===================

## Framework Building instruction<br>

The Spil target will build for the current selected device type. The SDK will work for both Simulator and Device. 

## Including Spil.framework in another project<br>
1 Download one of the releases from the releases tap and unzip it.<br>
2 Copy SpilTV.framework to the root of your project. (should be located in the directory that contains the .xcodeproj file)<br>
3 Add a new 'Run Script' phase - ON TOP - of the Build Phases tab using the following Shell command and build the project: /usr/bin/python SpilTV.framework/setup.py $(PROJECT_NAME) 

Instead of step 3 it is also possible to run the setup script from the terminal using: 'python SpilTV.framework/setup.py YOUR_PROJECT_NAME'

## Documentation

http://www.spilgames.com/developers/integration/ios/ios-get-started/

fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios hi_match
```
fastlane ios hi_match
```
synchronous certificate 
 fastlane ios hi_match
### ios hi_match_all
```
fastlane ios hi_match_all
```
synchronous all 
 e.g. fastlane ios hi_match_all readonly:1
### ios hi_register_device
```
fastlane ios hi_register_device
```
add device and refetch provision file 
 e.g. fastlane ios hi_register_device
### ios hi_match_certs_migration
```
fastlane ios hi_match_certs_migration
```
migration existing certificate 
 e.g. fastlane ios hi_match_certs_migration

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

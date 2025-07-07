# kuzu-swift-demo
kuzu-swift-demo is a demo project that shows how to integrate [Kuzu Swift API bindings](https://github.com/kuzudb/kuzu-swift) into an iOS application. 

It shows how to:
- Create a Kuzu database
- Create node and relationship tables
- Copy data into the table
- Query data from the table
- Use the bundled full-text search index
- Use the bundled vector index

## Requirements
Xcode 16 or later, iOS 17 or later.

## Installation
1. Clone the repository
2. Open the project in Xcode
3. Select the target device or simulator
4. Build and run the project with `Cmd + R`

The required Kuzu Swift API bindings will be downloaded automatically when you build the project for the first time. The required datasets are bundled with the git repository, so you don't need to download them separately.

Note that if you would like to run the project on a physical device, you need to login to your Apple Developer account in Xcode and set up a provisioning profile for the project and may need to change the bundle identifier to a unique one in the project settings.


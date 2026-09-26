---
title: Installation
---

# Installation

## Swift Package Manager (recommended)

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/jjjkkkjjj/Matft", from: "0.3.3"),
],
targets: [
    .target(name: "YourTarget", dependencies: ["Matft"]),
]
```

### Xcode

- Project > Package Dependencies > **+**

  ![Build Setting](https://user-images.githubusercontent.com/16914891/77144994-b0c72280-6aca-11ea-8633-1fb1a13ec74d.png)

- Enter `https://github.com/jjjkkkjjj/Matft` and select the rules

  ![select](https://user-images.githubusercontent.com/16914891/77144995-b1f84f80-6aca-11ea-8f4d-911bd96013cb.png)

- To update: File > Packages > Update to Latest Package Versions

  ![update](https://user-images.githubusercontent.com/16914891/77145225-4367c180-6acb-11ea-98ea-8d7a5a2a669f.png)

## Carthage / CocoaPods

:::warning
These installations are **outdated**. Please install Matft via SwiftPM.
:::

### Carthage

```bash
echo 'github "jjjkkkjjj/Matft"' > Cartfile
carthage update ### or append '--platform ios'
```

Then import `Matft.framework` built by the above process to your project.

### CocoaPods

```bash
pod init  # skip if you already have a Podfile
```

Write `pod 'Matft'` in the Podfile:

```ruby
target 'your project' do
  pod 'Matft'
end
```

```bash
pod install
```

## Requirements

- **iOS / macOS:** Swift 6.1 or later, macOS 10.13+ / iOS 12+ (`platforms` in `Package.swift`)
- **tvOS / watchOS / visionOS:** SwiftPM's default minimum versions apply, but they are not tested
- **WebAssembly:** see [Contributing](../contributing.md#webassembly-build--test)

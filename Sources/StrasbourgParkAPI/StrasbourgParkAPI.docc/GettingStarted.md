# Getting Started

Create one API client and start fetching the data

## Overview

Using the API is really simple. Just instantiate one ``ParkingAPIClient`` instance:

```swift
// Instantiate the default client
// This will use the default ``URLSession`` configuration and a page of 10 elements
let client = ParkingAPIClient()

// To override the configuration
let client = ParkingAPIClient(configuration: .background, pageSize: 5)
```

### Using the closure API 

```swift
client.getLocations { (result) in
    switch result {
        case .success(let locations):
            print("Locations: \(locations)")
        case .failure(let error):
            print("Error during the download: \(error)")
    }
}
```

### Using the Combine API 

```swift
client.getLocationsPublisher().sink { result in
    if case .failure(let error) = result {
        print("Error: \(result)")
    }   
} receiveValue: { result in
    print("Response: \(result)")

}
```

### Using the async API

```swift
let client = ParkingAPIClient()

do {
    let response = try await client.fetchLocations()
    print("Response: \(response)")
} catch let error {
    print("Error: \(error)")
}
```

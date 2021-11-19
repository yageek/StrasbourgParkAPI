# StrasbourgParkAPI

A simple swift package giving access to the strasbourg park open api.

Reference can be found [here](https://yageek.github.io/StrasbourgParkAPI/).

## Usage
You can interact with the framework using callback closures responses, Combine or async methods

### Callback closures 

```swift
let client = ParkingAPIClient()
client.getLocations { (result) in
    switch result {
        case .success(let locations):
            print("Locations: \(locations)")
        case .failure(let error):
            print("Error during the download: \(error)")
    }
}
```

### Combine 

```swift
let client = ParkingAPIClient()
client.getLocationsPublisher().sink { result in
    if case .failure(let error) = result {
        print("Error: \(result)")
    }   
} receiveValue: { result in
    print("Response: \(result)")

}
```

### async

```swift
let client = ParkingAPIClient()

do {
    let response = try await client.fetchLocations()
    print("Response: \(response)")
} catch let error {
    print("Error: \(error)")
}
```




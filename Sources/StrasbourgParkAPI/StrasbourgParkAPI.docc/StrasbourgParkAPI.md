# ``StrasbourgParkAPI``

A simple swift package giving access to the Strasbourg open data for parking location and availability

## Overview

![The logo of strasbourg Open Data](strasbourg.png)

The city of Strasbourg provides several APIs to retrieve the location and the current status of one parking.
The two main API can be found here:

- [Parking locations](https://data.strasbourg.eu/explore/dataset/parkings/api/)
- [Parking status](https://data.strasbourg.eu/explore/dataset/occupation-parkings-temps-reel/api/)

The package provides three asynchronous API to deal with those datas. All of them can be manipulated through the same ``ParkingAPIClient``

## Topics

### Essentials

- <doc:GettingStarted>
- ``ParkingAPIClient``
- ``LocationOpenData``
- ``StatusOpenData``

### Callback APIs

- ``ParkingAPIClient/getLocations(completion:)``
- ``ParkingAPIClient/getStatus(completion:)``

### Combine APIs

- ``ParkingAPIClient/getLocationsPublisher()``
- ``ParkingAPIClient/getStatusPublisher()``

### Async APIs

- ``ParkingAPIClient/fetchLocations()``
- ``ParkingAPIClient/fetchStatus()``

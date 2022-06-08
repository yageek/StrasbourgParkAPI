//
//  SPParkingLocation.m
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import "SPParkingLocation.h"
@interface SPParkingLocation()
/// The reference of the parking on the API
@property(nonatomic, copy, readwrite) NSString *identifier;

/// The city where the parking is located
@property(nonatomic, copy, readwrite) NSString *city;

/// The zip code of the city where the parking is located
@property(nonatomic, copy, readwrite) NSString *zipCode;

/// The street part of the address of the parking
@property(nonatomic, copy, readwrite) NSString *street;

/// The complete address of the parking location
@property(nonatomic, copy, readwrite) NSString *address;

/// The location of the parking on a map
@property(nonatomic, strong, readwrite) CLLocation *location;

/// The URL of the web page provided by the Strasbourg server
@property(nonatomic, strong, readwrite) NSURL *URL;

/// The name of the parking:
@property(nonatomic, copy, readwrite) NSString *name;

/// The description of the parking
@property(nonatomic, copy, readwrite, nullable) NSString *parkingDescription;

/// Whether or not the location has improved accessibility for non hearing people
@property(nonatomic, assign, readwrite) BOOL deafAccess;

/// Whether or not the location has improved accessibility for people suffering from deficiency
@property(nonatomic, assign, readwrite) BOOL deficientAccess;

/// Whether or not the location has improved accessibility for elder people
@property(nonatomic, assign, readwrite) BOOL elderAccess;

/// Whether or not the location has improved accessibility for people using a wheel chair
@property(nonatomic, assign, readwrite) BOOL wheelChairAccess;

/// Whether or not the location has improved accessibility for non seeing people
@property(nonatomic, assign, readwrite) BOOL blindAccess;
@end
@implementation SPParkingLocation

@end

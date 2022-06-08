//
//  SPParkingLocation.h
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
NS_ASSUME_NONNULL_BEGIN

@interface SPParkingLocation : NSObject
/// The reference of the parking on the API
@property(nonatomic, copy, readonly) NSString *identifier;

/// The city where the parking is located
@property(nonatomic, copy, readonly) NSString *city;

/// The zip code of the city where the parking is located
@property(nonatomic, copy, readonly) NSString *zipCode;

/// The street part of the address of the parking
@property(nonatomic, copy, readonly) NSString *street;

/// The complete address of the parking location
@property(nonatomic, copy, readonly) NSString *address;

/// The location of the parking on a map
@property(nonatomic, strong, readonly) CLLocation *location;

/// The URL of the web page provided by the Strasbourg server
@property(nonatomic, strong, readonly) NSURL *URL;

/// The name of the parking:
@property(nonatomic, copy, readonly) NSString *name;

/// The description of the parking
@property(nonatomic, copy, readonly, nullable) NSString *parkingDescription;

/// Whether or not the location has improved accessibility for non hearing people
@property(nonatomic, assign, readonly) BOOL deafAccess;

/// Whether or not the location has improved accessibility for people suffering from deficiency
@property(nonatomic, assign, readonly) BOOL deficientAccess;

/// Whether or not the location has improved accessibility for elder people
@property(nonatomic, assign, readonly) BOOL elderAccess;

/// Whether or not the location has improved accessibility for people using a wheel chair
@property(nonatomic, assign, readonly) BOOL wheelChairAccess;

/// Whether or not the location has improved accessibility for non seeing people
@property(nonatomic, assign, readonly) BOOL blindAccess;

@end

NS_ASSUME_NONNULL_END

//
//  SPParkingStatus.h
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPParkingStatus : NSObject

/// The reference of the resource on the server
@property(nonatomic, copy, readonly) NSString *identifier;

/// The name of the parking
@property(nonatomic, copy, readonly) NSString *name;

/// The state of the parking
@property(nonatomic, assign, readonly) NSInteger etat;

/// The total of available free slots
@property(nonatomic, assign, readonly) NSUInteger free;

/// The total capacity of the parking
@property(nonatomic, assign, readonly) NSUInteger total;

/// Some description on the parking
@property(nonatomic, copy, readonly) NSString *parkingDescription;

/// Some information available to the users. Either one NSString or NSNumber instance
@property(nullable, nonatomic, copy, readonly) id usersInfo;

@end

NS_ASSUME_NONNULL_END

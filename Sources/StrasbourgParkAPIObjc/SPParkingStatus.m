//
//  SPParkingStatus.m
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import "SPParkingStatus.h"

@interface SPParkingStatus()

@property(nonatomic, copy, readwrite) NSString *identifier;
@property(nonatomic, copy, readwrite) NSString *name;
@property(nonatomic, assign, readwrite) NSInteger etat;
@property(nonatomic, assign, readwrite) NSUInteger free;
@property(nonatomic, assign, readwrite) NSUInteger total;
@property(nonatomic, copy, readwrite) NSString *parkingDescription;
@property(nullable, nonatomic, copy, readwrite) id usersInfo;

@end

@implementation SPParkingStatus

@end

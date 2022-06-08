//
//  SPParkingResponse+Private.h
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import "SPParkingResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPParkingResponse<ObjectType> (Private)
@property(nonatomic, assign, readwrite) NSInteger total;
@property(nonatomic, strong, readwrite) NSTimeZone *timeZone;
@property(nonatomic, assign, readwrite) NSInteger count;
@property(nonatomic, assign, readwrite) NSInteger start;
@property(nonatomic, copy, readwrite) NSArray<ObjectType> *records;
@end

NS_ASSUME_NONNULL_END

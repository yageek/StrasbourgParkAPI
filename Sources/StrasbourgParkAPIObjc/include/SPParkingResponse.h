//
//  SPParkingResponse.h
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPParkingResponse<ObjectType> : NSObject

@property(nonatomic, assign, readonly) NSInteger total;
@property(nonatomic, strong, readonly) NSTimeZone *timeZone;
@property(nonatomic, assign, readonly) NSInteger count;
@property(nonatomic, assign, readonly) NSInteger start;
@property(nonatomic, copy, readonly) NSArray<ObjectType> *records;

@end

NS_ASSUME_NONNULL_END

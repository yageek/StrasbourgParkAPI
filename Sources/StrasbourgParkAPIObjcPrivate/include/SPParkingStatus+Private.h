//
//  SPParkingStatus+Private.h
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import "SPParkingStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPParkingStatus (Private)

@property(nonatomic, copy, readwrite) NSString *identifier;
@property(nonatomic, copy, readwrite) NSString *name;
@property(nonatomic, assign, readwrite) NSInteger etat;
@property(nonatomic, assign, readwrite) NSUInteger free;
@property(nonatomic, assign, readwrite) NSUInteger total;
@property(nonatomic, copy, readwrite) NSString *parkingDescription;
@property(nullable, nonatomic, copy, readwrite) id usersInfo;

-(instancetype) initWithIdenfifier:(NSString*) identifier
                              name:(NSString*) name
                              etat:(NSInteger) etat
                              free:(NSUInteger) free
                             total:(NSUInteger) total
                       description:(NSString *) description
                         usersInfo:(nullable id) usersInfo;
@end

NS_ASSUME_NONNULL_END

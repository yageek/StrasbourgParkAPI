//
//  SPParkingStatus+Private.m
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import "SPParkingStatus+Private.h"

@implementation SPParkingStatus (Private)

@dynamic identifier;
@dynamic name;
@dynamic etat;
@dynamic free;
@dynamic total;
@dynamic parkingDescription;
@dynamic usersInfo;

- (instancetype)initWithIdenfifier:(NSString *)identifier
                              name:(NSString *)name
                              etat:(NSInteger)etat
                              free:(NSUInteger)free
                             total:(NSUInteger)total
                       description:(NSString *)description
                         usersInfo:(id)usersInfo {
    
    self = [super init];
    
    if (self) {
        self.identifier = identifier;
        self.name = name;
        self.etat = etat;
        self.free = free;
        self.total = total;
        self.parkingDescription = description;
        self.usersInfo = usersInfo;
    }
    return self;
}
@end

//
//  SPParkingLocation+Private.m
//  
//
//  Created by Heinrich Yannick on 08/06/2022.
//

#import "SPParkingLocation+Private.h"

@implementation SPParkingLocation (Private)
@dynamic identifier;
@dynamic city;
@dynamic zipCode;
@dynamic street;
@dynamic address;
@dynamic location;
@dynamic URL;
@dynamic name;
@dynamic parkingDescription;
@dynamic deafAccess;
@dynamic deficientAccess;
@dynamic elderAccess;
@dynamic wheelChairAccess;
@dynamic blindAccess;

-(instancetype) initWithIdentifier:(NSString *)identifier
                              city:(NSString *)city
                           zipCode:(NSString *)zipCode
                            street:(NSString *)street
                           address:(NSString *)address
                          location:(CLLocation *)location
                               URL:(NSURL *)URL
                              name:(NSString *)name
                parkingDescription:(NSString *)parkingDescription
                        deafAccess:(BOOL )deafAccess
                   deficientAccess:(BOOL )deficientAccess
                       elderAccess:(BOOL )elderAccess
                  wheelChairAccess:(BOOL )wheelChairAccess
                       blindAccess:(BOOL) blindAccess {
    
    self = [super init];
    
    if (self) {
         self.identifier = identifier;
         self.city = city;
         self.zipCode = zipCode;
         self.street = street;
         self.address = address;
         self.location = location;
         self.URL = URL;
         self.name = name;
         self.parkingDescription = parkingDescription;
         self.deafAccess = deafAccess;
         self.deficientAccess = deficientAccess;
         self.elderAccess = elderAccess;
         self.wheelChairAccess = wheelChairAccess;
        self.blindAccess = blindAccess;
    }
    return self;
    
}
@end

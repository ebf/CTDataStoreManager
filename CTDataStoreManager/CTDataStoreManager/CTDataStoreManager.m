//
//  CTDataStoreManager.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "CTDataStoreManager.h"



@implementation CTDataStoreManager

#pragma mark - Initialization

- (id)init 
{
    if (self = [super init]) {
        
    }
    return self;
}

@end





#pragma mark - Singleton implementation

@implementation CTDataStoreManager (Singleton)

+ (id)sharedInstance 
{
    static NSMutableDictionary *_sharedDataStoreManagers = nil;
//    static id _instance = nil;
    
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDataStoreManagers = [NSMutableDictionary dictionary];
//        _instance = [[super allocWithZone:NULL] init];
    });
    
    NSString *uniqueKey = NSStringFromClass(self.class);
    id instance = [_sharedDataStoreManagers objectForKey:uniqueKey];
    
    if (!instance) {
        instance = [[super allocWithZone:NULL] init];
        [_sharedDataStoreManagers setObject:instance forKey:uniqueKey];
    }
    
    return instance;
}

+ (id)allocWithZone:(NSZone *)zone 
{	
	return [self sharedInstance];	
}

- (id)copyWithZone:(NSZone *)zone 
{
    return self;	
}

@end

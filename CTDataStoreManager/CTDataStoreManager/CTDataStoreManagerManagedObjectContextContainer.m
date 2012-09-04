//
//  CTDataStoreManagerManagedObjectContextContainer.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 04.09.12.
//  Copyright 2012 Home. All rights reserved.
//

#import "CTDataStoreManagerManagedObjectContextContainer.h"



@interface CTDataStoreManagerManagedObjectContextContainer () {
    
}

@end



@implementation CTDataStoreManagerManagedObjectContextContainer

#pragma mark - Initialization

- (id)init 
{
    if (self = [super init]) {
        // Initialization code
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    if (_deallocationCallback) {
        _deallocationCallback(self);
    }
    
}

#pragma mark - Private category implementation ()

@end

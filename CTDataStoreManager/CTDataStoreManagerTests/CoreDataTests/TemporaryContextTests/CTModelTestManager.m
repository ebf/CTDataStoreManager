//
//  CTModelTestManager.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "CTModelTestManager.h"



@implementation CTModelTestManager

#pragma mark - setters and getters

- (NSString *)managedObjectModelName
{
    return @"Model";
}

- (NSBundle *)contentBundle
{
    return [NSBundle bundleForClass:self.class];
}

- (void)cleanup
{
    _managedObjectModel = nil;
    _managedObjectContext = nil;
    _persistentStoreCoordinator = nil;
    
    NSURL *dataStoreURL = self.dataStoreURL;
    NSURL *temporaryDataStoreURL = self.temporaryDataStoreURL;
    
    [[NSFileManager defaultManager] removeItemAtURL:dataStoreURL error:NULL];
    [[NSFileManager defaultManager] removeItemAtURL:temporaryDataStoreURL error:NULL];
}

@end

//
//  CTSimpleStoreManager.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "CTSimpleStoreManager.h"



@implementation CTSimpleStoreManager

#pragma mark - setters and getters

- (NSString *)managedObjectModelName
{
    return @"SimpleStore";
}

- (NSBundle *)contentBundle
{
    return [NSBundle bundleForClass:self.class];
}

@end

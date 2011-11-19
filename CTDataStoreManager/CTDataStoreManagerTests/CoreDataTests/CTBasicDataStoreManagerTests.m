//
//  CTBasicDataStoreManagerTests.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "CTBasicDataStoreManagerTests.h"
#import "CTDataStoreManager.h"
#import "CTEmptyDataStoreTestManager.h"
#import "CTSimpleStoreManager.h"

@implementation CTBasicDataStoreManagerTests

- (void)testEmptyDataStoreManager
{
    CTDataStoreManager *manager = [CTDataStoreManager sharedInstance];
    
    STAssertThrows([manager managedObjectContext], @"CTDataStoreManager is an abstract superclass and not supposed to work without subclassing");
}

- (void)testEmptySubclassDataStoreManager
{
    CTEmptyDataStoreTestManager *manager = [CTEmptyDataStoreTestManager sharedInstance];
    
    STAssertThrows([manager managedObjectContext], @"CTEmptyDataStoreTestManager is not supposed to work without an existing Data model.");
}

- (void)testExistingStoreManager
{
    CTSimpleStoreManager *manager = [CTSimpleStoreManager sharedInstance];
    
    STAssertNotNil(manager.managedObjectContext, @"managedObjectContext of CTSimpleStoreManager cannot be nil");
}

@end

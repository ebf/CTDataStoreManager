//
//  CTDataStoreManagerTests.m
//  CTDataStoreManagerTests
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "CTDataStoreManagerTests.h"
#import "CTSingletonTestStore1.h"
#import "CTSingletonTestStore2.h"

@implementation CTDataStoreManagerTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSharedInstances
{
    id store1 = [CTSingletonTestStore1 sharedInstance];
    id store2 = [CTSingletonTestStore2 sharedInstance];
    
    STAssertFalse(store1 == store2, @"CTDataStoreManager should return a unique instance for each subclass in sharedInstance");
}

@end

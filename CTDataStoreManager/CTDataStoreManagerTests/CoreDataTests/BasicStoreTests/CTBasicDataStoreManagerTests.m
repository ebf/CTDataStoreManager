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

- (void)setUp
{
    [super setUp];
    
    CTSimpleStoreManager *manager = [CTSimpleStoreManager sharedInstance];
    [[NSFileManager defaultManager] removeItemAtURL:manager.dataStoreURL error:NULL];
}

- (void)tearDown
{
    [super tearDown];
    
    CTSimpleStoreManager *manager = [CTSimpleStoreManager sharedInstance];
    [[NSFileManager defaultManager] removeItemAtURL:manager.dataStoreURL error:NULL];
}

- (void)testExistingStoreManager
{
    CTSimpleStoreManager *manager = [CTSimpleStoreManager sharedInstance];
    
    NSManagedObjectContext *context = manager.managedObjectContext;
    STAssertNotNil(context, @"managedObjectContext of CTSimpleStoreManager cannot be nil");
    
    id entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                              inManagedObjectContext:context];
    STAssertNotNil(entity, @"new created entity of CTSimpleStoreManager cannot be nil");
    
    [entity setValue:@"HALLO" forKey:@"attribute"];
    
    [context save:NULL];
}

@end

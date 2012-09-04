//
//  CTMigrationTests.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "CTMigrationTests.h"
#import "CTTestMigrationStoreManager.h"

@implementation CTMigrationTests

- (void)setUp
{
    [super setUp];
    
    // move old store to store URL
    CTTestMigrationStoreManager *manager = [CTTestMigrationStoreManager sharedInstance];
    NSURL *destinationURL = manager.dataStoreURL;
    
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:NULL];
    
    NSURL *oldVersionURL = [manager.contentBundle URLForResource:@"TestMigrationStore_version_1"
                                                   withExtension:@"sqlite"];
    
    [[NSFileManager defaultManager] copyItemAtURL:oldVersionURL
                                            toURL:destinationURL
                                            error:NULL];
}

- (void)tearDown
{
    [super tearDown];
    
    // remove store
    CTTestMigrationStoreManager *manager = [CTTestMigrationStoreManager sharedInstance];
    NSURL *destinationURL = manager.dataStoreURL;
    
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:NULL];
}

- (void)testSuccessfulMigration
{
    CTTestMigrationStoreManager *manager = [CTTestMigrationStoreManager sharedInstance];
    
    NSManagedObjectContext *context = manager.mainThreadContext;
    STAssertNotNil(context, @"managedObjectContext of CTTestMigrationStoreManager cannot be nil");
    
    id entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                              inManagedObjectContext:context];
    STAssertNotNil(entity, @"new created entity of CTSimpleStoreManager cannot be nil");
    
    [entity setValue:[NSDate date] forKey:@"date"];
    [entity setValue:@"Hallöh" forKey:@"attribute"];
    [context save:NULL];
}

@end

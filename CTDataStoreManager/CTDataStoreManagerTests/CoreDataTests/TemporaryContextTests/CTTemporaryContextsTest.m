//
//  CTTemporaryContextsTest.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "CTTemporaryContextsTest.h"
#import "CTModelTestManager.h"

@implementation CTTemporaryContextsTest

- (void)tearDown
{
    [super tearDown];
    
    CTModelTestManager *manager = [CTModelTestManager sharedInstance];
    
    [manager cleanup];
}

- (void)testBeginContext
{
    CTModelTestManager *manager = [CTModelTestManager sharedInstance];
    
    [manager beginContext];
    STAssertThrows([manager beginContext], @"CTDataStoreManager cannot start multiple contexts");
}

- (void)testEndContext
{
    CTModelTestManager *manager = [CTModelTestManager sharedInstance];
    
    STAssertThrows([manager endContext:NULL], @"manager cannot end context if non began");
}

- (void)testSave
{
    CTModelTestManager *manager = [CTModelTestManager sharedInstance];
    NSDate *now = [NSDate date];
    
    [manager beginContext];
    
    id entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                              inManagedObjectContext:manager.managedObjectContext];
    [entity setValue:now forKey:@"date"];
    
    NSError *error = nil;
    STAssertTrue([manager endContext:&error saveChanges:YES], @"CTModelTestManager should be able to save changes (%@)", error);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Entity"];
    request.predicate = [NSPredicate predicateWithFormat:@"date == %@", now];
    
    NSArray *fetchedObjects = [manager.managedObjectContext executeFetchRequest:request error:&error];
    
    STAssertTrue(fetchedObjects.count == 1, @"CTModelTestManager should return exactly one object after inserting one object\narray: %@\nerror:%@", fetchedObjects, error);
}

- (void)testDiscardingOfChanges
{
    CTModelTestManager *manager = [CTModelTestManager sharedInstance];
    NSDate *now = [NSDate date];
    
    [manager beginContext];
    
    id entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                              inManagedObjectContext:manager.managedObjectContext];
    [entity setValue:now forKey:@"date"];
    
    NSError *error = nil;
    STAssertTrue([manager endContext:&error saveChanges:NO], @"CTModelTestManager should be able to save changes (%@)", error);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Entity"];
    request.predicate = [NSPredicate predicateWithFormat:@"date == %@", now];
    
    NSArray *fetchedObjects = [manager.managedObjectContext executeFetchRequest:request error:&error];
    
    STAssertTrue(fetchedObjects.count == 0, @"CTModelTestManager should return exactly one object after discarding changes\narray: %@\nerror:%@", fetchedObjects, error);
}

- (void)testSaveWithChanges
{
    CTModelTestManager *manager = [CTModelTestManager sharedInstance];
    NSDate *now = [NSDate date];
    
    id entity = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                              inManagedObjectContext:manager.managedObjectContext];
    [entity setValue:now forKey:@"date"];
    
    STAssertThrows([manager beginContext], @"CTDataStoreManager cannot begin new context with unsaved changes");
}

@end

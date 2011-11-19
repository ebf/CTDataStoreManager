//
//  CTDataStoreManager.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "CTDataStoreManager.h"

@interface CTDataStoreManager ()

/**
 @return    Returns self.dataStoreRootURL and creates directory if it does not exist.
 */
@property (nonatomic, readonly) NSURL *_dataStoreRootURL;

@end


@implementation CTDataStoreManager

#pragma mark - setters and getters

- (NSString *)managedObjectModelName
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSURL *)dataStoreRootURL
{
    return [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory 
                                                  inDomains:NSUserDomainMask].lastObject;
}

- (NSURL *)dataStoreURL
{
    NSURL *dataStoreRootURL = self._dataStoreRootURL;
    NSString *dataStoreFileName = [NSString stringWithFormat:@"%@.sqlite", self.managedObjectModelName];
    
    return [dataStoreRootURL URLByAppendingPathComponent:dataStoreFileName];
}

- (NSURL *)_dataStoreRootURL
{
    NSURL *dataStoreRootURL = self.dataStoreRootURL;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataStoreRootURL.relativePath isDirectory:NULL]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dataStoreRootURL.relativePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil 
                                                        error:&error];
        
        NSAssert(error != nil, @"error while creating dataStoreRootURL '%@':\n\n%@", dataStoreRootURL, error);
    }
    
    return dataStoreRootURL;
}

- (NSBundle *)contentBundle
{
    return [NSBundle mainBundle];
}

#pragma mark - Initialization

- (id)init 
{
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - CoreData

- (NSManagedObjectModel *)managedObjectModel 
{
    if (!_managedObjectModel) {
        NSString *managedObjectModelName = self.managedObjectModelName;
        NSURL *modelURL = [self.contentBundle URLForResource:managedObjectModelName withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    
    return _managedObjectModel;
}

- (NSManagedObjectContext *)managedObjectContext 
{
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *persistentStoreCoordinator = self.persistentStoreCoordinator;
        
        if (persistentStoreCoordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            _managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
        }
    }
    
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator 
{
    if (!_persistentStoreCoordinator) {
        NSURL *storeURL = self.dataStoreURL;
        NSManagedObjectModel *managedObjectModel = self.managedObjectModel;
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
//            if (![self _migrateDataStoreAtURL:storeURL ofType:NSSQLiteStoreType toFinalModel:[self managedObjectModel] error:&error]) {
//                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//                abort();
//            } else {
//                if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
//                {
//                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//                    abort();
//                }
//            }
        }
    }
    
    return _persistentStoreCoordinator;
}

@end





#pragma mark - Singleton implementation

@implementation CTDataStoreManager (Singleton)

+ (id)sharedInstance 
{
    static NSMutableDictionary *_sharedDataStoreManagers = nil;
    
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDataStoreManagers = [NSMutableDictionary dictionary];
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

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

- (NSURL *)temporaryDataStoreURL
{
    NSURL *dataStoreRootURL = self._dataStoreRootURL;
    NSString *dataStoreFileName = [NSString stringWithFormat:@"%@_fallback.sqlite", self.managedObjectModelName];
    
    return [dataStoreRootURL URLByAppendingPathComponent:dataStoreFileName];
}

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
            
            if (![self performMigrationFromDataStoreAtURL:storeURL toFinalModel:managedObjectModel error:&error]) {
                NSAssert(NO, @"unresolved error adding store:\n\n%@", error);
                abort();
            } else {
                if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
                    NSAssert(NO, @"unresolved error adding store:\n\n%@", error);
                    abort();
                }
            }
        }
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - managing contexts

- (void)beginContext
{
    NSURL *dataStoreFallbackURL = self.temporaryDataStoreURL;
    NSURL *dataStoreURL = self.dataStoreURL;
    
    NSManagedObjectContext *context = self.managedObjectContext;
    
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:dataStoreFallbackURL.relativePath isDirectory:NULL] == NO, @"dataStore fallback cannot exists when starting a new context. Make sure to always pair a beginContext call with an endContext one.");
    NSAssert([[NSThread currentThread] isMainThread], @"dataStore fallback can only be created from the main thread.");
    NSAssert(context.hasChanges == NO, @"the current context cannot have uncommited changes before creating a fallback. Make sure to always pair a beginContext call with an endContext one.");
    
    [[NSFileManager defaultManager] copyItemAtURL:dataStoreURL
                                            toURL:dataStoreFallbackURL
                                            error:NULL];
}

- (BOOL)endContext:(NSError *__autoreleasing *)error
{
    return [self endContext:error saveChanges:YES];
}

- (BOOL)endContext:(NSError *__autoreleasing *)error saveChanges:(BOOL)saveChanges
{
    NSURL *dataStoreFallbackURL = self.temporaryDataStoreURL;
    NSURL *dataStoreURL = self.dataStoreURL;
    
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:dataStoreFallbackURL.relativePath isDirectory:NULL] == YES, @"dataStore fallback must exists when ending a context. Make sure to always pair a beginContext call with an endContext one.");
    NSAssert([[NSThread currentThread] isMainThread], @"dataStore fallback can only be created from the main thread.");
    
    if (saveChanges) {
        [[NSFileManager defaultManager] removeItemAtURL:dataStoreFallbackURL
                                                  error:NULL];
        
        return [self saveContext:error];
    } else {
        _managedObjectContext = nil;
        _managedObjectModel = nil;
        _persistentStoreCoordinator = nil;
        
        [[NSFileManager defaultManager] removeItemAtURL:dataStoreURL
                                                  error:NULL];
        
        if (![[NSFileManager defaultManager] moveItemAtURL:dataStoreFallbackURL toURL:dataStoreURL error:error]) {
            return NO;
        }
        
        return YES;
    }
}

- (BOOL)saveContext:(NSError *__autoreleasing *)error
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext) {
        if (managedObjectContext.hasChanges && ![managedObjectContext save:error]) {
            NSLog(@"Unresolved error %@, %@", *error, [*error userInfo]);
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Migration

- (BOOL)performMigrationFromDataStoreAtURL:(NSURL *)dataStoreURL 
                              toFinalModel:(NSManagedObjectModel *)finalObjectModel 
                                     error:(NSError **)error
{
    NSString *type = NSSQLiteStoreType;
    NSDictionary *sourceStoreMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type
                                                                                                   URL:dataStoreURL
                                                                                                 error:error];
    
    // error while fetching metadata
    if (!sourceStoreMetadata) {
        return NO;
    }
    
    // migration succesful.
    if ([finalObjectModel isConfiguration:nil compatibleWithStoreMetadata:sourceStoreMetadata]) {
        *error = nil;
        return YES;
    }
    
    NSArray *bundles = [NSArray arrayWithObject:self.contentBundle];
    NSManagedObjectModel *souceObjectModel = [NSManagedObjectModel mergedModelFromBundles:bundles
                                                                         forStoreMetadata:sourceStoreMetadata];
    
    NSAssert(souceObjectModel != nil, @"Unable to find source model for %@", sourceStoreMetadata);
    
    NSMutableArray *objectModelPaths = [NSMutableArray array];
    NSArray *allManagedObjectModels = [self.contentBundle pathsForResourcesOfType:@"momd" 
                                                                      inDirectory:nil];
    
    for (NSString *managedObjectModelPath in allManagedObjectModels) {
        NSArray *array = [self.contentBundle pathsForResourcesOfType:@"mom" 
                                                         inDirectory:managedObjectModelPath.lastPathComponent];
        
        [objectModelPaths addObjectsFromArray:array];
    }
    
    NSArray *otherModels = [self.contentBundle pathsForResourcesOfType:@"mom" inDirectory:nil];
    [objectModelPaths addObjectsFromArray:otherModels];
    
    NSAssert(objectModelPaths.count > 0, @"at least one NSManagedObjectModel must be available in the contentBundle");
    
    NSMappingModel *mappingModel = nil;
    NSManagedObjectModel *targetModel = nil;
    NSString *modelPath = nil;
    
    for (modelPath in objectModelPaths) {
        NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
        targetModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        mappingModel = [NSMappingModel mappingModelFromBundles:bundles
                                                forSourceModel:souceObjectModel
                                              destinationModel:targetModel];
        
        if (mappingModel) {
            break;
        }
    }
    
    NSAssert(mappingModel != nil, @"No mapping model found for dataStore at URL %@", dataStoreURL);
    
    NSMigrationManager *migrationManager = [[NSMigrationManager alloc] initWithSourceModel:souceObjectModel
                                                                          destinationModel:targetModel];
    
    NSString *modelName = modelPath.lastPathComponent.stringByDeletingPathExtension;
    NSString *storeExtension = dataStoreURL.path.pathExtension;
    
    NSString *storePath = dataStoreURL.path.stringByDeletingPathExtension;
    
    NSString *destinationPath = [NSString stringWithFormat:@"%@.%@.%@", storePath, modelName, storeExtension];
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
    
    if (![migrationManager migrateStoreFromURL:dataStoreURL type:type options:nil withMappingModel:mappingModel toDestinationURL:destinationURL destinationType:type destinationOptions:nil error:error]) {
        return NO;
    }
    
    // migration was succesful, remove old store and replace with new store
    if (![[NSFileManager defaultManager] removeItemAtURL:dataStoreURL error:error]) {
        return NO;
    }
    
    // replace with new store
    if (![[NSFileManager defaultManager] moveItemAtURL:destinationURL toURL:dataStoreURL error:error]) {
        return NO;
    }
    
    return [self performMigrationFromDataStoreAtURL:dataStoreURL
                                       toFinalModel:finalObjectModel
                                              error:error];
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
    
    @synchronized(self) {
        NSString *uniqueKey = NSStringFromClass(self.class);
        id instance = [_sharedDataStoreManagers objectForKey:uniqueKey];
        
        if (!instance) {
            instance = [[super allocWithZone:NULL] init];
            [_sharedDataStoreManagers setObject:instance forKey:uniqueKey];
        }
        
        return instance;
    }
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

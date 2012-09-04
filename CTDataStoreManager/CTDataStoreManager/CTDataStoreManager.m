//
//  CTDataStoreManager.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright 2011 Home. All rights reserved.
//

#import "CTDataStoreManager.h"
#import <UIKit/UIKit.h>
#import "NSMutableArray+CTDataStoreManager.h"
#import "CTDataStoreManagerManagedObjectContextContainer.h"

NSString *const CTDataStoreManagerClassKey = @"CTDataStoreManagerClassKey";
NSString *const CTDataStoreManagerErrorDomain = @"CTDataStoreManagerErrorDomain";

char *const CTDataStoreManagerManagedObjectContextWrapperKey;


@interface CTDataStoreManager () {
    NSMutableArray *_managedObjectContexts;
}

/**
 @return    Returns self.dataStoreRootURL and creates directory if it does not exist.
 */
@property (nonatomic, readonly) NSURL *_dataStoreRootURL;

/**
 @abstract  replaces the current store with the fallback store if the fallback store is available.
 */
- (void)_replaceExistingStoreWithBackupIfRequired;

/**
 @abstract Callback for notifications that trigger automatic data store saving.
 */
- (void)_automaticallySaveDataStore;

/**
 @abstract logs error and calls abort()
 */
- (void)_failFromCriticalError:(NSError *)error;

- (void)_managedObjectContextDidSaveNotificationCallback:(NSNotification *)notification;

@end


@implementation CTDataStoreManager
@synthesize automaticallyDeletesNonSupportedDataStore=_automaticallyDeletesNonSupportedDataStore, automaticallySavesDataStoreOnEnteringBackground=_automaticallySavesDataStoreOnEnteringBackground;

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
        
        NSAssert(error == nil, @"error while creating dataStoreRootURL '%@':\n\nerror: \"%@\"", dataStoreRootURL, error);
    }
    
    return dataStoreRootURL;
}

- (NSBundle *)contentBundle
{
    return [NSBundle bundleForClass:self.class];
}

#pragma mark - Initialization

- (id)init
{
    if (self = [super init]) {
        _managedObjectContexts = [NSMutableArray arrayWithWeakReferences];
        
        _automaticallySavesDataStoreOnEnteringBackground = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_automaticallySaveDataStore)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_automaticallySaveDataStore)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
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

- (NSManagedObjectContext *)mainThreadContext
{
    if (!_mainThreadContext) {
        _mainThreadContext = [self newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType
                                  automaticallyMergesChangesWithOtherContexts:YES];
    }
    
    return _mainThreadContext;
}

- (NSManagedObjectContext *)backgroundThreadContext
{
    if (!_backgroundThreadContext) {
        _backgroundThreadContext = [self newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType
                                        automaticallyMergesChangesWithOtherContexts:YES];
    }
    
    return _backgroundThreadContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator 
{
    if (!_persistentStoreCoordinator) {
        NSURL *storeURL = self.dataStoreURL;
        NSManagedObjectModel *managedObjectModel = self.managedObjectModel;
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        [self _replaceExistingStoreWithBackupIfRequired];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            error = nil;
            // first try to migrate to the new store
            if (![self performMigrationFromDataStoreAtURL:storeURL toDestinationModel:managedObjectModel error:&error]) {
                // migration was not successful
                if (self.automaticallyDeletesNonSupportedDataStore) {
                    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:NULL];
                    
                    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
                        [self _failFromCriticalError:error];
                    }
                } else {
                    [self _failFromCriticalError:error];
                }
            } else {
                // migration was successful, just add the store
                if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
                    // unable to add store, fail
                    [self _failFromCriticalError:error];
                }
            }
        }
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - managing contexts

- (BOOL)saveManagedObjectContext:(NSManagedObjectContext *)managedObjectContext 
                           error:(NSError **)error
{
    
    NSError *myError = nil;
    if (managedObjectContext) {
        NSString *classString = objc_getAssociatedObject(managedObjectContext, &CTDataStoreManagerClassKey);
        NSAssert([classString isEqualToString:NSStringFromClass(self.class)], @"managedObjectContext (%@) was not created by this CTDataStoreManager (%@). Make sure to only perform this action from a NSManagedObjectContext obtained by -[%@ managedObjectContext] or -[%@ newManagedObjectContext]", managedObjectContext, self, NSStringFromClass(self.class), NSStringFromClass(self.class));
        
        if (managedObjectContext.hasChanges && ![managedObjectContext save:&myError]) {
            NSLog(@"Error while saving context: %@, %@", myError, [myError userInfo]);
            if (error) {
                *error = myError;
            }
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Migration

- (NSManagedObjectContext *)newManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
                           automaticallyMergesChangesWithOtherContexts:(BOOL)automaticallyMergesChangesWithOtherContexts
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
    context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    objc_setAssociatedObject(context, &CTDataStoreManagerClassKey,
                             NSStringFromClass(self.class), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (automaticallyMergesChangesWithOtherContexts) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_managedObjectContextDidSaveNotificationCallback:) name:NSManagedObjectContextDidSaveNotification object:context];
        
        [_managedObjectContexts addObject:context];
        
        CTDataStoreManagerManagedObjectContextContainer *container = [[CTDataStoreManagerManagedObjectContextContainer alloc] init];
        container.context = context;
        [container setDeallocationCallback:^(CTDataStoreManagerManagedObjectContextContainer *container) {
            [_managedObjectContexts removeObject:container.context];
        }];
    }
    
    return context;
}

- (BOOL)performMigrationFromDataStoreAtURL:(NSURL *)dataStoreURL 
                        toDestinationModel:(NSManagedObjectModel *)destinationModel 
                                     error:(NSError **)error
{
    NSAssert(error != nil, @"Error pointer cannot be nil");
    
    NSString *type = NSSQLiteStoreType;
    NSDictionary *sourceStoreMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type
                                                                                                   URL:dataStoreURL
                                                                                                 error:error];
    
    // error while fetching metadata
    if (!sourceStoreMetadata) {
        return NO;
    }
    
    // migration succesful.
    if ([destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceStoreMetadata]) {
        *error = nil;
        return YES;
    }
    
    NSArray *bundles = [NSArray arrayWithObject:self.contentBundle];
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:bundles
                                                                    forStoreMetadata:sourceStoreMetadata];
    
    if (!sourceModel) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unable to find NSManagedObjectModel for store metadata %@", sourceStoreMetadata]
                                                             forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:CTDataStoreManagerErrorDomain code:CTDataStoreManagerManagedObjectModelNotFound userInfo:userInfo];
        return NO;
    }
    
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
    
    if (objectModelPaths.count == 0) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"No NSManagedObjectModel found in bundle %@", self.contentBundle]
                                                             forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:CTDataStoreManagerErrorDomain code:CTDataStoreManagerManagedObjectModelNotFound userInfo:userInfo];
        return NO;
    }
    
    NSMappingModel *mappingModel = nil;
    NSManagedObjectModel *targetModel = nil;
    NSString *modelPath = nil;
    
    for (modelPath in objectModelPaths) {
        NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
        targetModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        mappingModel = [NSMappingModel mappingModelFromBundles:bundles
                                                forSourceModel:sourceModel
                                              destinationModel:targetModel];
        
        if (mappingModel) {
            break;
        }
    }
    
    if (!mappingModel) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unable to find NSMappingModel for store at URL %@", dataStoreURL]
                                                             forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:CTDataStoreManagerErrorDomain code:CTDataStoreManagerMappingModelNotFound userInfo:userInfo];
        return NO;
    }
    
    NSMigrationManager *migrationManager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel
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
                                 toDestinationModel:destinationModel
                                              error:error];
}

#pragma mark - private implementation ()

- (void)_managedObjectContextDidSaveNotificationCallback:(NSNotification *)notification
{
    NSManagedObjectContext *changedContext = notification.object;
    
    for (NSManagedObjectContext *otherContext in _managedObjectContexts) {
        if (changedContext.persistentStoreCoordinator == otherContext.persistentStoreCoordinator) {
            if (otherContext != changedContext) {
                [otherContext performBlock:^{
                    [otherContext mergeChangesFromContextDidSaveNotification:notification];
                }];
            }
        }
    }
}

- (void)_replaceExistingStoreWithBackupIfRequired
{
    NSURL *temporaryDataStoreURL = self.temporaryDataStoreURL;
    NSURL *dataStoreURL = self.dataStoreURL;
    
    // there exist file at our fallback URL
    if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryDataStoreURL.relativePath isDirectory:NULL]) {
        // current dataStore exists, remove this one
        if ([[NSFileManager defaultManager] fileExistsAtPath:dataStoreURL.relativePath isDirectory:NULL]) {
            [[NSFileManager defaultManager] removeItemAtURL:dataStoreURL error:NULL];
        }
        
        // make fallback dataStore to current store.
        [[NSFileManager defaultManager] moveItemAtURL:temporaryDataStoreURL
                                                toURL:dataStoreURL
                                                error:NULL];
    }
}

- (void)_automaticallySaveDataStore
{
    if (self.automaticallySavesDataStoreOnEnteringBackground) {
        for (NSManagedObjectContext *context in _managedObjectContexts) {
            NSError *error = nil;
            if (![self saveManagedObjectContext:context error:&error]) {
                DLog(@"WARNING: Error while automatically saving changes of data store of class %@: %@", self, error);
            };
        }
    }
}

- (void)_failFromCriticalError:(NSError *)error
{
    NSLog(@"%@", error);
    abort();
}

@end

#pragma mark - CTQueryInterface

@implementation CTDataStoreManager (CTQueryInterface)

- (void)deleteAllManagedObjectsWithEntityName:(NSString *)entityName
{
    NSManagedObjectContext *context = self.mainThreadContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSError *error = nil;
    NSArray *objectsToBeDeleted = [context executeFetchRequest:request
                                                         error:&error];
    if (!objectsToBeDeleted) {
        DLog(@"error performing fetch: %@", error);
    } else {
        for (NSManagedObject *object in objectsToBeDeleted) {
            [context deleteObject:object];
        }
    }
}

- (NSArray *)managedObjectsOfEntityNamed:(NSString *)entityName error:(NSError **)error
{
    return [self managedObjectsOfEntityNamed:entityName
                                   predicate:nil
                                       error:error];
}

- (NSArray *)managedObjectsOfEntityNamed:(NSString *)entityName predicate:(NSPredicate *)predicate error:(NSError **)error
{
    return [self managedObjectsOfEntityNamed:entityName
                                   predicate:predicate
                             sortDescriptors:nil
                                       error:error];
}

- (NSArray *)managedObjectsOfEntityNamed:(NSString *)entityName
                               predicate:(NSPredicate *)predicate
                         sortDescriptors:(NSArray *)sortDescriptors
                                   error:(NSError **)error
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = predicate;
    request.sortDescriptors = sortDescriptors;
    
    return [self managedObjectsWithFetchRequest:request
                                          error:error];
}

- (NSArray *)managedObjectsWithFetchRequest:(NSFetchRequest *)fetchRequest
                                      error:(NSError **)error
{
    NSError *myError = nil;
    NSArray *result = [self.mainThreadContext executeFetchRequest:fetchRequest
                                                            error:&myError];
    
    if (myError) {
        if (error) {
            *error = myError;
        }
        DLog(@"WARNING: Fetching objects resulted in error: %@", *error);
    }
    
    return result;
}

- (void)deleteManagedObjects:(NSArray *)managedObjects
{
    for (id object in managedObjects) {
        [self.mainThreadContext deleteObject:object];
    }
    
    [self saveManagedObjectContext:self.mainThreadContext error:NULL];
}

- (id)uniqueManagedObjectOfEntityNamed:(NSString *)entityName
                             predicate:(NSPredicate *)predicate
                                 error:(NSError **)error
{
    NSError *myError = nil;
    NSArray *array = [self managedObjectsOfEntityNamed:entityName
                                             predicate:predicate
                                                 error:&myError];
    
    if (myError) {
        if (error) {
            *error = myError;
        }
    } else {
        if (array.count > 0) {
            return [array objectAtIndex:0];
        } else {
            return [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                 inManagedObjectContext:self.mainThreadContext];
        }
    }
    
    return nil;
}

@end


#pragma mark - Singleton implementation

@implementation CTDataStoreManager (Singleton)

+ (id)sharedInstance 
{
    @synchronized(self) {
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

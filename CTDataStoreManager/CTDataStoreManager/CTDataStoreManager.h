//
//  CTDataStoreManager.h
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright 2011 Home. All rights reserved.
//

@class NSFetchRequest, NSManagedObjectModel, NSManagedObjectContext, NSPersistentStoreCoordinator;

extern NSString *const CTDataStoreManagerErrorDomain;

enum {
    CTDataStoreManagerMappingModelNotFound = 1,
    CTDataStoreManagerManagedObjectModelNotFound
};

/**
 @abstract  An NSObject singleton which can manage a NSManagedObjectContext with corresponding NSSQLiteStoreType store. CTDataStoreManager can also perform automatic migration between different store versions.
 @discussion
 Migration: To perform automatic dataStore migration, make sure there is a unique migration path available in your contentsBundle. CTDataStoreManager expects exactly one migration from an old model to a new one. If this condition is met, CTDataStoreManager will start at the current dataStore model, migrate to the next available one, migrate from the new one to the next model until the final model is reached.
 @warning   CTDataStoreManager is an abstract class which needs to be subclassed. You need to at least implement -[CTDataStoreManager managedObjectModelName] and return the name of a valid NSManagedObjectModel.
 */
@interface CTDataStoreManager : NSObject {
@protected
    BOOL _automaticallyDeletesNonSupportedDataStore;
    BOOL _automaticallySavesDataStoreOnEnteringBackground;
}

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSManagedObjectContext *mainThreadContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundThreadContext;

- (NSManagedObjectContext *)newManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
                           automaticallyMergesChangesWithOtherContexts:(BOOL)automaticallyMergesChangesWithOtherContexts;

/**
 @discussion    If YES, then the data store will autmatically be saved in application did enter background or application will terminate. Default is YES.
 */
@property (nonatomic, readonly) BOOL automaticallySavesDataStoreOnEnteringBackground;

/**
 @return    Returns the name of the managedObjectModel that was used to develop the Store in Xcode.
 @warning   Abstract method. Must be implemented by subclasses.
 */
@property (nonatomic, readonly) NSString *managedObjectModelName;

/**
 @return    Returns the root URL in which the dataStore will be located. Default is NSLibraryDirectory.
 */
@property (nonatomic, readonly) NSURL *dataStoreRootURL;

/**
 @abstract  Returns the URL where the actual DataStore will be stored. Default is dataStoreRootURL/managedObjectModelName.sqli
 */
@property (nonatomic, readonly) NSURL *dataStoreURL;

/**
 @return        Returns the NSBundle, in which all CoreData files can be found. Default is [NSBundle mainBundle].
 @discussion    Overwrite and return custom bundle for lets say unit tests or if you store your files in a different place then the main bundle.
 */
@property (nonatomic, readonly) NSBundle *contentBundle;

/**
 @return    Returns an URL to a temporary location where a fallback of the dataStore will be stored. See beginContext for more information. Default is dataStoreRootURL/managedObjectModelName_fallback.sqlite
 */
@property (nonatomic, readonly) NSURL *temporaryDataStoreURL;

/**
 If YES, the existing data store will automatically be deleted in case of a newer version is required and no migration is found. Default is YES if DEBUG is defined. Otherwise NO:
 */
@property (nonatomic, assign) BOOL automaticallyDeletesNonSupportedDataStore;

/**
 @abstract      performs a migration for an old dataStore at dataStoreURL to finalObjectModel.
 @discussion    Will be automatically called if the _persistentStoreCoordinator was not able to add a store to it.
 @warning       This method requires a unique migration path described above.
 */
- (BOOL)performMigrationFromDataStoreAtURL:(NSURL *)dataStoreURL 
                        toDestinationModel:(NSManagedObjectModel *)destinationModel 
                                     error:(NSError **)error;

/**
 @abstract      Saves a specific NSManagedObjectContext.
 @discussion    Intended for instances obtained by -[CTDataStoreManager newManagedObjectContext] to perform thread safe save operation.
 @warning       Make sure to only call this method with a managedObjectContext obtained from this CTDataStoreManager.
 */
- (BOOL)saveManagedObjectContext:(NSManagedObjectContext *)managedObjectContext 
                           error:(NSError **)error;

@end

/**
 @warning all API calls are made on the main thread
 */
@interface CTDataStoreManager (CTQueryInterface)

/**
 @abstract  Deletes all entities in this managedObjectContext with a given name.
 @param     entityName: The name of the entity objects that will be deleted
 */
- (void)deleteAllManagedObjectsWithEntityName:(NSString *)entityName
                       inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 Fetches all entyties of a given name.
 */
- (NSArray *)managedObjectsOfEntityNamed:(NSString *)entityName
                  inManagedObjectContext:(NSManagedObjectContext *)context
                                   error:(NSError **)error;

/**
 Fetches all entities of a given name that match predicate.
 */
- (NSArray *)managedObjectsOfEntityNamed:(NSString *)entityName
                               predicate:(NSPredicate *)predicate
                  inManagedObjectContext:(NSManagedObjectContext *)context
                                   error:(NSError **)error;

/**
 Fetches all entities of a given name that match predicate and are sorted by sortDescriptors
 */
- (NSArray *)managedObjectsOfEntityNamed:(NSString *)entityName
                               predicate:(NSPredicate *)predicate
                         sortDescriptors:(NSArray *)sortDescriptors
                  inManagedObjectContext:(NSManagedObjectContext *)context
                                   error:(NSError **)error;

/**
 Fetches NSManagedObject's by fetchRequest.
 */
- (NSArray *)managedObjectsWithFetchRequest:(NSFetchRequest *)fetchRequest
                     inManagedObjectContext:(NSManagedObjectContext *)context
                                      error:(NSError **)error;

/**
 Deletes all managed objects in managedObjects.
 */
- (void)deleteManagedObjects:(NSArray *)managedObjects;

/**
 Fetches a unique managed object and if it doesnt exists, created a new one.
 */
- (id)uniqueManagedObjectOfEntityNamed:(NSString *)entityName
                             predicate:(NSPredicate *)predicate
                inManagedObjectContext:(NSManagedObjectContext *)context
                                 error:(NSError **)error;

- (id)uniqueManagedObjectOfEntityNamed:(NSString *)entityName
                             predicate:(NSPredicate *)predicate
                inManagedObjectContext:(NSManagedObjectContext *)context
                     createIfNonExists:(BOOL)crcreateIfNonExists
                                 error:(NSError **)error;

@end


/**
 @category  CTDataStoreManager (Singleton)
 @abstract  Singleton category
 */
@interface CTDataStoreManager (Singleton)

/**
 @return    returns a unique Singleton instance for each subclass.
 */
+ (id)sharedInstance;

@end

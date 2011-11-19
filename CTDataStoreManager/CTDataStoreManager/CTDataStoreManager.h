//
//  CTDataStoreManager.h
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright 2011 Home. All rights reserved.
//



/**
 @class     CTDataStoreManager
 @abstract  An NSObject singleton which can manage a NSManagedObjectContext with corresponding NSSQLiteStoreType store. CTDataStoreManager can also perform automatic migration between different store versions.
 @discussion
    Migration: To perform automatic dataStore migration, make sure there is a unique migration path available in your contentsBundle. CTDataStoreManager expects exactly one migration from an old model to a new one. If this condition is met, CTDataStoreManager will start at the current dataStore model, migrate to the next available one, migrate from the new one to the next model until the final model is reached.
 @warning   CTDataStoreManager is an abstract class which needs to be subclassed. You need to at least implement -[CTDataStoreManager managedObjectModelName] and return the name of a valid model.
 */
@interface CTDataStoreManager : NSObject {
@private
    NSManagedObjectModel *_managedObjectModel;
    NSManagedObjectContext *_managedObjectContext;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

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
 @abstract      performs a migration for an old dataStore at dataStoreURL to finalObjectModel.
 @discussion    Will be automatically called if the _persistentStoreCoordinator was not able to add a store to it.
 @warning       This method requires a unique migration path described above.
 */
- (BOOL)performMigrationFromDataStoreAtURL:(NSURL *)dataStoreURL 
                              toFinalModel:(NSManagedObjectModel *)finalObjectModel 
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

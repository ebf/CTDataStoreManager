//
//  CTDataStoreManager.h
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 19.11.11.
//  Copyright 2011 Home. All rights reserved.
//



/**
 @class     CTDataStoreManager
 @abstract  <#abstract comment#>
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

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
    
}

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

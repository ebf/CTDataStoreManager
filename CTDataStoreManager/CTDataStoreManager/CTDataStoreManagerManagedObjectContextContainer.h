//
//  CTDataStoreManagerManagedObjectContextContainer.h
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 04.09.12.
//  Copyright 2012 Home. All rights reserved.
//



/**
 @abstract  <#abstract comment#>
 */
@interface CTDataStoreManagerManagedObjectContextContainer : NSObject

@property (nonatomic, weak) NSManagedObjectContext *context;
@property (nonatomic, copy) void(^deallocationCallback)(CTDataStoreManagerManagedObjectContextContainer *blockSelf);

@end

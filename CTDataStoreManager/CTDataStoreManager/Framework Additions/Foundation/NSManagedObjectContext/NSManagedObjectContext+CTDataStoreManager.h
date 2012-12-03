//
//  NSManagedObjectContext+CTDataStoreManager.h
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 03.12.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

typedef void(^CTNSManagedObjectContextDeallocationCallback)(NSManagedObjectContext *sender);



@interface NSManagedObjectContext (CTDataStoreManager)

@property (nonatomic, copy) CTNSManagedObjectContextDeallocationCallback deallocationHandler;

@end

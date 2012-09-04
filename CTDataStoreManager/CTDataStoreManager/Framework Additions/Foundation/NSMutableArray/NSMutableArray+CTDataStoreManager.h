//
//  NSArray+CTDataStoreManager.h
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 04.09.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

@interface NSMutableArray (CTDataStoreManager)

+ (NSMutableArray *)arrayWithWeakReferences;
+ (NSMutableArray *)arrayWithWeakReferencesWithCapacity:(NSUInteger)capacity;

@end

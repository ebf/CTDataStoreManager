//
//  NSArray+CTDataStoreManager.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 04.09.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "NSMutableArray+CTDataStoreManager.h"

const void *CTDataStoreManagerNSMutableArrayWeakRetainCallBack(CFAllocatorRef allocator, const void *value);
const void *CTDataStoreManagerNSMutableArrayWeakRetainCallBack(CFAllocatorRef allocator, const void *value)
{
    return value;
}

void CTDataStoreManagerNSMutableArrayWeakReleaseCallBack(CFAllocatorRef allocator, const void *value);
void CTDataStoreManagerNSMutableArrayWeakReleaseCallBack(CFAllocatorRef allocator, const void *value)
{
    
}

@implementation NSMutableArray (CTDataStoreManager)

+ (NSMutableArray *)arrayWithWeakReferences
{
    return [self arrayWithWeakReferencesWithCapacity:0];
}

+ (NSMutableArray *)arrayWithWeakReferencesWithCapacity:(NSUInteger)capacity
{
    CFArrayCallBacks callbacks = {0, CTDataStoreManagerNSMutableArrayWeakRetainCallBack, CTDataStoreManagerNSMutableArrayWeakReleaseCallBack, CFCopyDescription, CFEqual};
    return (__bridge_transfer id)CFArrayCreateMutable(NULL, capacity, &callbacks);
}

@end

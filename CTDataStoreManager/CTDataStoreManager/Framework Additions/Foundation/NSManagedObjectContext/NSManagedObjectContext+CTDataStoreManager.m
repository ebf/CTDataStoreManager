//
//  NSManagedObjectContext+CTDataStoreManager.m
//  CTDataStoreManager
//
//  Created by Oliver Letterer on 03.12.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "NSManagedObjectContext+CTDataStoreManager.h"

char *const CTDataStoreManagerNSManagedObjectContextDeallocationHandlerKey;

void CTDataStoreManagerClass_swizzleSelector(Class class, SEL originalSelector, SEL newSelector);
void CTDataStoreManagerClass_swizzleSelector(Class class, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);
    if(class_addMethod(class, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

@implementation NSManagedObjectContext (CTDataStoreManager)

+ (void)load
{
    CTDataStoreManagerClass_swizzleSelector([NSManagedObjectContext class], @selector(dealloc), @selector(__hoockedCTDataStoreManagerDealloc));
}

- (void)__hoockedCTDataStoreManagerDealloc
{
    CTNSManagedObjectContextDeallocationCallback callback = self.deallocationHandler;
    if (callback) {
        callback(self);
    }
    
    [self __hoockedCTDataStoreManagerDealloc];
}

- (void)setDeallocationHandler:(CTNSManagedObjectContextDeallocationCallback)deallocationHandler
{
    objc_setAssociatedObject(self, &CTDataStoreManagerNSManagedObjectContextDeallocationHandlerKey,
                             deallocationHandler, OBJC_ASSOCIATION_COPY);
}

- (CTNSManagedObjectContextDeallocationCallback)deallocationHandler
{
    return [[objc_getAssociatedObject(self, &CTDataStoreManagerNSManagedObjectContextDeallocationHandlerKey) retain] autorelease];
}

@end

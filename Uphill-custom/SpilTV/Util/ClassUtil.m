//
//  ClassUtil.m
//  Spil
//
//  Created by Frank Slofstra on 25/05/16.
//  Copyright © 2016 Spil Games. All rights reserved.
//

#import "ClassUtil.h"
#import <objc/runtime.h>

@implementation ClassUtil

+ (void)copyParent:(id)parent intoChild:(id)child {
    id parentClass = [parent class];
    NSString *propertyName;
    unsigned int outCount, i;
    
    //Get a list of properties for the parent class.
    objc_property_t *properties = class_copyPropertyList(parentClass, &outCount);
    
    //Loop through the parents properties.
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        
        //Convert the property to a string.
        propertyName = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];
        
        //Get the parent's value for the property
        id value = [parent valueForKey:propertyName];
        
        //..and copy into the child.
        if ([value conformsToProtocol:@protocol(NSCopying)])
        {
            [child setValue:[value copy] forKey:propertyName];
        }
        else
        {
            [child setValue:value forKey:propertyName];
        }
    }
}

@end

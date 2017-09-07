//
//  Record.h
//  Auditor 2
//
//  Created by Viktor Radulov on 9/7/17.
//  Copyright © 2017 KROMTECH ALLIANCE CORP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Record : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *event;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSString *time;

- (instancetype)initWithXML:(NSXMLElement *)XML;

@end

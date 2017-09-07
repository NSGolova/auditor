//
//  Record.m
//  Auditor 2
//
//  Created by Viktor Radulov on 9/7/17.
//  Copyright © 2017 KROMTECH ALLIANCE CORP. All rights reserved.
//

#import "Record.h"

#import <sys/proc_info.h>
#include <libproc.h>

@implementation Record

@synthesize event = _event;
@synthesize name = _name;
@synthesize path = _path;

- (instancetype)initWithXML:(NSXMLElement *)XML
{
	self = [super init];
	
	if (self)
	{
		_event = [XML attributeForName:@"event"].stringValue;
		for (NSXMLNode *node in XML.children)
		{
			if ([node.name isEqualToString:@"path"])
			{
				_path = [NSString stringWithFormat:@"%@%@%@", node.stringValue, _path != nil ? @", " : @"", _path != nil ? _path : @""];
			}
		}
		_name = [self nameForXML:XML];
		_time = [NSString stringWithFormat:@"%@%@", [XML attributeForName:@"time"].stringValue, [XML attributeForName:@"msec"].stringValue];;
	}
	
	return self;
}

- (NSString *)nameForXML:(NSXMLElement *)XML
{
	pid_t pid = 0;
	for (NSXMLElement *child in [XML children])
	{
		NSString *pidString = [child attributeForName:@"pid"].stringValue;
		
		if (pidString != nil)
		{
			pid = (pid_t)pidString.integerValue;
			break;
		}
		
	}
	
	char pathBuffer [PROC_PIDPATHINFO_MAXSIZE];
	proc_pidpath(pid, pathBuffer, sizeof(pathBuffer));
	
	char nameBuffer[256];
	
	NSInteger position = strlen(pathBuffer);
	while(position >= 0 && pathBuffer[position] != '/')
	{
		position--;
	}
	
	strcpy(nameBuffer, pathBuffer + position + 1);
	
	return [NSString stringWithUTF8String:nameBuffer];
}

@end

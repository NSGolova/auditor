//
//  ViewController.m
//  Auditor 2
//
//  Created by Viktor Radulov on 9/7/17.
//  Copyright © 2017 KROMTECH ALLIANCE CORP. All rights reserved.
//

#import "ViewController.h"
#import "Record.h"

@interface ViewController ()

@property (nonatomic, copy) NSString *croppedString;
@property (nonatomic, strong) NSTask *task;
@property (nonatomic) BOOL suspend;

@property (nonatomic, readonly) NSString *label;
@property (nonatomic, readonly) NSString *count;

@property (nonatomic, strong, readonly) NSMutableArray<Record *> *records;
@property (nonatomic, strong) NSArray *sortDescriptors;

@end

@implementation ViewController

@synthesize records = _records;

- (NSMutableArray<Record *> *)records
{
	if (_records == nil)
	{
		_records = [NSMutableArray array];
	}
	return _records;
}

- (NSString *)count
{
	return [NSString stringWithFormat:@"%lu", (unsigned long)self.records.count];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCount
{
	return [NSSet setWithObject:@"records"];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"event" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]];
}

- (NSString *)label
{
	return self.suspend || self.task == nil ? @"Start" : @"Pause";
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingLabel
{
	return [NSSet setWithObjects:@"suspend", @"task", nil];
}

- (IBAction)toggle:(id)sender
{
	if (self.task == nil)
	{
		//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
					   {
		NSTask *task = [[NSTask alloc] init];
		task.launchPath = @"/bin/sh";
		task.arguments = @[@"-c", @"auditreduce -r golova /private/var/audit/20170823192611.crash_recovery | praudit -xl"];
		
		NSPipe *pipe = [NSPipe pipe];
		task.standardOutput = pipe;
		
		NSFileHandle *fileHandle = [pipe fileHandleForReading];
		[fileHandle waitForDataInBackgroundAndNotify];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:fileHandle];
						   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
						   {
		[task launch];
						   });
		self.task = task;
					   }
					   //);
	}
	else
	{
		int pid = self.task.processIdentifier;
		NSTask *task = [[NSTask alloc] init];
		task.launchPath = @"/bin/kill";
		NSMutableArray *arguments = [NSMutableArray arrayWithObjects:[self stringFromInt:pid], [self stringFromInt:pid + 1], [self stringFromInt:pid + 2], nil];
		if (!self.suspend)
		{
			[arguments insertObject:@"-STOP" atIndex:0];
		}
		else
		{
			[arguments insertObject:@"-CONT" atIndex:0];
		}
		task.arguments = arguments;
		[task launch];
		[task waitUntilExit];
		if (task.terminationStatus == 0)
		{
			self.suspend = !self.suspend;
		}
	}
}

- (NSString *)stringFromInt:(int)inte
{
	return [NSString stringWithFormat:@"%i", inte];
}

- (void)receivedData:(NSNotification *)notif
{
	NSFileHandle *fh = [notif object];
	NSData *data = [fh availableData];
	if (data.length > 0)
	{
		[fh waitForDataInBackgroundAndNotify];
		NSString *str = [NSString stringWithFormat:@"%@%@", self.croppedString ?: @"", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
		for (NSString *string in [str componentsSeparatedByString:@"\n"])
		{
			if (string.length > 0)
			{
				NSError *error = nil;
				NSXMLElement *element = [[NSXMLElement alloc] initWithXMLString:string error:&error];
				
				if (error == nil)
				{
					NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:self.records.count];
					[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"records"];
					[self.records addObject:[[Record alloc] initWithXML:element]];
					[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"records"];
					
					self.croppedString = string;
				}
			}
		}
	}
}


@end

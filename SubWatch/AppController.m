//
//  AppController.m
//  ImgHistory
//
//  Created by Adam Thorsen on 5/25/08.
//  Copyright 2008 Owyhee Software, LLC. All rights reserved.
//

#import "AppController.h"

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{
    AppController *ac = (AppController *)userData;
	size_t i;
	for(i=0; i<numEvents; i++){
        [ac addModifiedImagesAtPath:[(NSArray *)eventPaths objectAtIndex:i]];
		[ac updateLastEventId:eventIds[i]];
	}

}

@implementation AppController

- (id)init
{
	self = [super init];
    if (self != nil) {
        fm = [NSFileManager defaultManager];
        images = [NSMutableArray new];
    }    
	return self;
}

- (void)awakeFromNib
{
	[table setRowHeight:100.0];
	[self registerDefaults];
	appStartedTimestamp = [NSDate date];
    pathModificationDates = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"pathModificationDates"] mutableCopy];
	lastEventId = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastEventId"];
	[self initializeEventStream];
}

- (void)initializeEventStream
{
    NSString *myPath = NSHomeDirectory();
    NSArray *pathsToWatch = [NSArray arrayWithObject:myPath];
    void *appPointer = (void *)self;
    FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
    NSTimeInterval latency = 3.0;

	stream = FSEventStreamCreate(NULL,
	                             &fsevents_callback,
	                             &context,
	                             (CFArrayRef) pathsToWatch,
	                             [lastEventId unsignedLongLongValue],
	                             (CFAbsoluteTime) latency,
	                             kFSEventStreamCreateFlagUseCFTypes 
	);

	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
}


- (NSApplicationTerminateReply)applicationShouldTerminate: (NSApplication *)app
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:lastEventId forKey:@"lastEventId"];
	[defaults setObject:pathModificationDates forKey:@"pathModificationDates"];
	[defaults synchronize];
    FSEventStreamStop(stream);
    FSEventStreamInvalidate(stream);
    return NSTerminateNow;
}

- (void)registerDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *appDefaults = [NSDictionary
	                             dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:kFSEventStreamEventIdSinceNow], [NSMutableDictionary new], nil]
	                             forKeys:[NSArray arrayWithObjects:@"lastEventId", @"pathModificationDates", nil]];
	[defaults registerDefaults:appDefaults];
}


- (void)updateLastModificationDateForPath: (NSString *)path
{
	[pathModificationDates setObject:[NSDate date] forKey:path];
}

- (NSDate *)lastModificationDateForPath: (NSString *)path
{
	if(nil != [pathModificationDates valueForKey:path]) {
		return [pathModificationDates valueForKey:path];
	}
	else{
		return appStartedTimestamp;
	}
}


- (void)updateLastEventId: (uint64_t)eventId
{
	lastEventId = [NSNumber numberWithUnsignedLongLong:eventId];
}

- (void)addModifiedImagesAtPath: (NSString *)path
{
	NSArray *contents = [fm contentsOfDirectoryAtPath:path error:nil];
	NSString* fullPath = nil;
    BOOL addedImage = false;

	for(NSString* node in contents) {
        fullPath = [NSString stringWithFormat:@"%@/%@",path,node];
        if ([self fileIsImage:fullPath])
		{
            NSDictionary *fileAttributes = [fm attributesOfItemAtPath:fullPath error:NULL];
			NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
			if([fileModDate compare:[self lastModificationDateForPath:path]] == NSOrderedDescending) {
				[images addObject:fullPath];
                addedImage = true;
			}
		}
	}

    if(addedImage){
        [table reloadData];
    }

	[self updateLastModificationDateForPath:path];
}

- (BOOL)fileIsImage: (NSString *)path
{
    NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
    return [sharedWorkspace type:[sharedWorkspace typeOfFile:path error:NULL] conformsToType:@"public.image"];
}

- (NSUInteger)numberOfRowsInTableView: (NSTableView *)aTable
{
	return [images count];
}

- (id)tableView: (NSTableView *)aTable objectValueForTableColumn: (NSTableColumn *)aCol row: (int)aRow
{
	NSImage *image = [[NSImage alloc] initByReferencingFile:[images objectAtIndex:([images count] - 1) - aRow]];
	return image;
}
@end

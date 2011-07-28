//
//  AppController.h
//  ImgHistory
//
//  Created by Adam Thorsen on 5/25/08.
//  Copyright 2008 Owyhee Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    NSFileManager* fm;
    IBOutlet NSTableView* table;
    NSMutableArray* images;
    NSMutableDictionary* pathModificationDates;
    NSDate* appStartedTimestamp;
    NSNumber* lastEventId;
    FSEventStreamRef stream;
}

- (void) registerDefaults;
- (void) initializeEventStream;
- (void) addModifiedImagesAtPath: (NSString *)path;
- (void)updateLastEventId: (uint64_t) eventId;
- (BOOL)fileIsImage: (NSString *)path;

@end

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]);
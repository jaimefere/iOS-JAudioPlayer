//
//  FileUtils.h
//  iOSMediaPlayer
//
//  Created by Jaime Fernández on 06/02/14.
//  Copyright (c) 2014 Jaime Fernández. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileUtils : NSObject

+ (void) saveDataToFile:(NSData *) receivedData toAudio:(NSString *) audioName;
+ (void) saveDataToTempFile:(NSData *) receivedData toAudio:(NSString *) audioName withContentSize:(unsigned long long)totalSize;
+ (NSMutableData *) existTempAudio:(NSString*) audioName;
+ (NSUInteger) tempAudioSize:(NSString*) audioName;
+ (BOOL) existAudio:(NSString*) audioName;
+ (void) removeTempAudioFile:(NSString *) audioFile;

@end

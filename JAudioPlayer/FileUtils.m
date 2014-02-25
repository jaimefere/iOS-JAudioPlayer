//
//  FileUtils.m
//  iOSMediaPlayer
//
//  Created by Jaime Fernández on 06/02/14.
//  Copyright (c) 2014 Jaime Fernández. All rights reserved.
//

#import "FileUtils.h"

@implementation FileUtils


+ (void) saveDataToFile:(NSData *) receivedData toAudio:(NSString *) audioName{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, audioName];
    
    [FileUtils removeTempAudioFile:audioName];
    
    if ( receivedData ) {
        [receivedData writeToFile:filePath atomically:YES];
    }
}

+ (void) saveDataToTempFile:(NSData *) receivedData toAudio:(NSString *) audioName withContentSize:(unsigned long long)totalSize{
    audioName = [NSString stringWithFormat:@"%llu____%@",totalSize, audioName];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, audioName];
    
    if ( receivedData ) {
        [receivedData writeToFile:filePath atomically:YES];
    }
}

+ (void) removeTempAudioFile:(NSString *) audioFile{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryContent = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    for (NSString *filename in directoryContent)  {
        if ([filename rangeOfString:audioFile].location != NSNotFound) {
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:nil];
        }
    }
}

+ (NSMutableData *) existTempAudio:(NSString*) audioName{
    NSMutableData *response = [[NSMutableData alloc] init];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryContent = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    for (NSString *filename in directoryContent)  {
        NSRange titleRange = [filename rangeOfString:[NSString stringWithFormat:@"____%@",audioName] options:NSLiteralSearch];
        if(titleRange.location != NSNotFound) {
            response = [[fileManager contentsAtPath:[documentsDirectory stringByAppendingPathComponent:filename]]mutableCopy];
        }
    }
    
    return response;
}

+ (NSUInteger) tempAudioSize:(NSString*) audioName{
    NSUInteger response = 0;
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryContent = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    for (NSString *filename in directoryContent)  {
        NSRange titleRange = [filename rangeOfString:[NSString stringWithFormat:@"____%@",audioName] options:NSLiteralSearch];
        if(titleRange.location != NSNotFound) {
            NSString *totalBytes = [filename substringWithRange:NSMakeRange(0, titleRange.location)];
            response = [totalBytes intValue];
        }
    }
    
    return response;
}

+ (BOOL) existAudio:(NSString*) audioName{
    BOOL response = NO;
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryContent = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    for (NSString *filename in directoryContent)  {
        NSRange tempRange = [filename rangeOfString:[NSString stringWithFormat:@"____%@",audioName] options:NSLiteralSearch];
        NSRange titleRange = [filename rangeOfString:audioName options:NSLiteralSearch];
        if((titleRange.location != NSNotFound) && (tempRange.location == NSNotFound)) {
            response = YES;
        }
    }
    return response;
}

@end

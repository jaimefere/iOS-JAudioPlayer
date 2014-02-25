//
//  JAPAppDelegate.h
//  JAudioPlayer
//
//  Created by Jaime Fernández on 25/02/14.
//  Copyright (c) 2014 Jaime Fernández. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>

@interface JAPAppDelegate : UIResponder <UIApplicationDelegate, AVAudioSessionDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

//
//  JMPViewController.h
//  iOSMediaPlayer
//
//  Created by Jaime Fernández on 05/02/14.
//  Copyright (c) 2014 Jaime Fernández. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
	DOWNLOADABLE,
    DOWNLOADING,
    INCOMPLETE_DOWNLOAD,
	DOWNLOADED,
	PLAYING
} SongStatusType;

@interface JAPViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate, UIScrollViewDelegate> {
    long long contentSize;
    SongStatusType songStatus;
    BOOL startPlaying;                  //Play song automatically when start app or change song
    BOOL downloadingAll;
    NSString *downloadingAudioName;
    NSMutableArray *downloadedSongs;
    NSMutableArray *undownloadedSongs;
    NSMutableArray *songsOrderToPlay;
    NSMutableArray *playedSongs;
}

@property (strong, nonatomic) NSArray *content;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSMutableData *receivedData;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSTimer *progressUpdater;

@property (weak, nonatomic) IBOutlet UITableView *tracksTableView;

@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;

@property (weak, nonatomic) IBOutlet UISlider *trackProgress;
- (IBAction)seekingTrack:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *randomButton;
@property (weak, nonatomic) IBOutlet UIButton *repeatButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadAllBarButton;

- (IBAction)randomAction:(id)sender;
- (IBAction)repeatAction:(id)sender;

- (IBAction)backAction:(id)sender;
- (IBAction)playAction:(id)sender;
- (IBAction)nextAction:(id)sender;

- (IBAction)downloadAllAction:(id)sender;

@end

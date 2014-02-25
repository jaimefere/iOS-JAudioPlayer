//
//  JMPViewController.m
//  iOSMediaPlayer
//
//  Created by Jaime Fernández on 05/02/14.
//  Copyright (c) 2014 Jaime Fernández. All rights reserved.
//


#import "JAPViewController.h"
#import "FileUtils.h"

@interface JAPViewController ()

@end

@implementation JAPViewController

@synthesize content = _content;

- (void)viewDidLoad
{
    [super viewDidLoad];
    downloadedSongs = [[NSMutableArray alloc] init];
    undownloadedSongs = [[NSMutableArray alloc] init];
    playedSongs = [[NSMutableArray alloc] init];
    [_trackProgress setThumbImage:[UIImage imageNamed:@"slider_thumb.png"] forState:UIControlStateNormal];
    [_backButton setBackgroundImage:[UIImage imageNamed:@"backward_icon.png"] forState:UIControlStateNormal];
    [_nextButton setBackgroundImage:[UIImage imageNamed:@"forward_icon.png"] forState:UIControlStateNormal];
    [self customizeToggleButtons];
    startPlaying = NO;
    downloadingAll = NO;
    [_trackProgress setValue:0.0];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self calculateDownloadedArrays];
    if ([songsOrderToPlay count] > 0) {
        [self goToRow:[[songsOrderToPlay objectAtIndex:0] integerValue]];
    } else {
        [self goToRow:0];
    }
    [self showDeleteAccessory];
	//Once the view has loaded then we can register to begin recieving controls and we can become the first responder
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_player stop];
    //End receiving events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [_player performSelector:@selector(play) withObject:nil afterDelay:0.01];
}

-(NSArray *)content
{
    if (!_content) {
        _content = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tracks" ofType:@"plist"]];
    }    
    return _content;
}

- (void) goToRow:(NSInteger) row{
    NSIndexPath *indexPath = [_tracksTableView indexPathForSelectedRow];
//    [self clearDeleteAccessoryWithIndexPath:indexPath];
    
    indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [_tracksTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
    [self setSongStatus];
    
    [self showDeleteAccessory];
}

- (void) setSongStatus{
    NSString *audioName = [[self.content objectAtIndex:_tracksTableView.indexPathForSelectedRow.row] valueForKey:@"name"];
    if (songStatus == DOWNLOADING) {
        [self stopConnection];
    }
    if (songStatus == PLAYING) {
        [self pauseSong];
    }
    if ([FileUtils existAudio:audioName]) {
        songStatus = DOWNLOADED;
        [self prepareToPlay];
        if (startPlaying && (_repeatButton.isSelected || ![playedSongs containsObject:[NSNumber numberWithInteger:_tracksTableView.indexPathForSelectedRow.row]])) {
            [self playSong];
            songStatus = PLAYING;
        }
    } else if([FileUtils tempAudioSize:audioName] > 0){
        _receivedData = [FileUtils existTempAudio:audioName];
        contentSize = [FileUtils tempAudioSize:audioName];
        songStatus = INCOMPLETE_DOWNLOAD;
        if (downloadingAll) {
            [self downloadTrack];
            songStatus = DOWNLOADING;
        }
    } else{
        contentSize = 0;
        _receivedData = [[NSMutableData alloc] init];
        [_receivedData setLength:0];
        [self pauseSong];
        songStatus = DOWNLOADABLE;
        if (downloadingAll) {
            [self downloadTrack];
            songStatus = DOWNLOADING;
        }
    }
    [self customizeUI];
}

- (void) calculateDownloadedArrays{
    for (int track=0; track<[_content count]; track++) {
        NSString *audioName = [[self.content objectAtIndex:track] valueForKey:@"name"];
        if ([FileUtils existAudio:audioName]) {
            [downloadedSongs addObject:[NSNumber numberWithInt:track]];
        } else{
            [undownloadedSongs addObject:[NSNumber numberWithInt:track]];
        }
    }
    
    if ([undownloadedSongs count] == 0) {
        [_downloadAllBarButton setEnabled:NO];
    }
    [self calculateSongOrder];
}

- (void) calculateSongOrder{
    songsOrderToPlay = [[NSMutableArray alloc] initWithArray:downloadedSongs];
    if (_randomButton.isSelected) {
        NSUInteger count = [songsOrderToPlay count];
        for (NSUInteger i = 0; i < count; ++i) {
            // Select a random element between i and end of array to swap with.
            NSInteger nElements = count - i;
            NSInteger n = arc4random_uniform(nElements) + i;
            [songsOrderToPlay exchangeObjectAtIndex:i withObjectAtIndex:n];
        }
    }
}


#pragma mark -
#pragma mark UI methods
- (void) customizeUI{
    switch (songStatus) {
        case DOWNLOADABLE:
            [self updateProgress];
            [_startLabel setText:@"0%"];
            [_endLabel setText:@"100%"];
            [_trackProgress setUserInteractionEnabled:NO];
            [_trackProgress setThumbImage:[UIImage new] forState:UIControlStateNormal];
            [_playButton setAttributedTitle:nil forState:UIControlStateNormal];
//            [_playButton setTitle:@"download" forState:UIControlStateNormal];
            [_playButton setBackgroundImage:[UIImage imageNamed:@"down_icon.png"] forState:UIControlStateNormal];
            break;
            
        case DOWNLOADING:
            [_endLabel setText:@"100%"];
            [_trackProgress setUserInteractionEnabled:NO];
            [_trackProgress setThumbImage:[UIImage new] forState:UIControlStateNormal];
            [_playButton setAttributedTitle:nil forState:UIControlStateNormal];
//            [_playButton setTitle:@"pause" forState:UIControlStateNormal];
            [_playButton setBackgroundImage:[UIImage imageNamed:@"pause_icon.png"] forState:UIControlStateNormal];
            break;
            
        case INCOMPLETE_DOWNLOAD:
            [self updateProgress];
            [_endLabel setText:@"100%"];
            [_trackProgress setUserInteractionEnabled:NO];
            [_trackProgress setThumbImage:[UIImage new] forState:UIControlStateNormal];
            [_playButton setAttributedTitle:nil forState:UIControlStateNormal];
//            [_playButton setTitle:@"download" forState:UIControlStateNormal];
            [_playButton setBackgroundImage:[UIImage imageNamed:@"down_icon.png"] forState:UIControlStateNormal];
            break;
            
        case DOWNLOADED:
            [self updateTrackTime];
            [_endLabel setText:[self trackTimeStringFromTimeInterval:_player.duration]];
            [_trackProgress setUserInteractionEnabled:YES];
            [_trackProgress setThumbImage:[UIImage imageNamed:@"slider_thumb.png"] forState:UIControlStateNormal];
            [_playButton setAttributedTitle:nil forState:UIControlStateNormal];
//            [_playButton setTitle:@"play" forState:UIControlStateNormal];
            [_playButton setBackgroundImage:[UIImage imageNamed:@"play_icon.png"] forState:UIControlStateNormal];
            break;
            
        default:
            //playing case
            [_endLabel setText:[self trackTimeStringFromTimeInterval:_player.duration]];
            [_trackProgress setUserInteractionEnabled:YES];
            [_trackProgress setThumbImage:[UIImage imageNamed:@"slider_thumb.png"] forState:UIControlStateNormal];
            [_playButton setAttributedTitle:nil forState:UIControlStateNormal];
//            [_playButton setTitle:@"pause" forState:UIControlStateNormal];
            [_playButton setBackgroundImage:[UIImage imageNamed:@"pause_icon.png"] forState:UIControlStateNormal];
            break;
    }
}

- (void)updateProgress {
    float progress = (float)[_receivedData length] / (float)contentSize;
    [_trackProgress setValue:progress];
    [_startLabel setText:[NSString stringWithFormat:@"%d%%",(int)(progress*100.0)]];
}

//- (void)updateTrackTime:(NSTimer *)timer {
- (void)updateTrackTime {
    [_trackProgress setValue:(_player.currentTime/_player.duration)];
    [_startLabel setText:[self trackTimeStringFromTimeInterval:_player.currentTime]];
}

- (NSString *) trackTimeStringFromTimeInterval:(NSTimeInterval) time{
    NSString *result = @"";
    int minutes = floor(time / 60);
    int seconds = round(time - minutes * 60);
    result = [NSString stringWithFormat:@"%@%d:",result,minutes];
    if (seconds < 10) {
        result = [NSString stringWithFormat:@"%@0%d",result,seconds];
    } else{
        result = [NSString stringWithFormat:@"%@%d",result,seconds];
    }
    
    return result;
}

- (void) showDeleteAccessory {
    for (NSIndexPath *indexPath in [_tracksTableView indexPathsForVisibleRows]) {
        [self clearDeleteAccessoryWithIndexPath:indexPath];
    }
    if ((songStatus != DOWNLOADABLE) && ([[_tracksTableView indexPathsForVisibleRows] containsObject:[_tracksTableView indexPathForSelectedRow]])) {
        UIImage *image = [UIImage imageNamed:@"close.png"];
        CGRect frameAccessory = CGRectMake(0, 0, 15, 15);
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:frameAccessory];
        [button setBackgroundImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(accessoryAction: event:) forControlEvents:UIControlEventTouchDown];
        [_tracksTableView cellForRowAtIndexPath:[_tracksTableView indexPathForSelectedRow]].accessoryView = button;
    }
}

- (void) clearDeleteAccessoryWithIndexPath:(NSIndexPath *) indexPath{
    NSString *audioName = [[self.content objectAtIndex:indexPath.row] valueForKey:@"name"];
    if ([FileUtils existAudio:audioName]) {
        [_tracksTableView cellForRowAtIndexPath:indexPath].accessoryView = nil;
        [[_tracksTableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [_tracksTableView cellForRowAtIndexPath:indexPath].accessoryView = nil;
        [[_tracksTableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryNone];
    }
}

- (void) customizeToggleButtons{
    [_repeatButton setBackgroundImage:[UIImage imageNamed:@"repeat_selected_icon.png"] forState:UIControlStateSelected];
    [_repeatButton setBackgroundImage:[UIImage imageNamed:@"repeat_not_selected_icon.png"] forState:UIControlStateNormal];
    [_randomButton setBackgroundImage:[UIImage imageNamed:@"random_selected_icon.png"] forState:UIControlStateSelected];
    [_randomButton setBackgroundImage:[UIImage imageNamed:@"random_not_selected_icon.png"] forState:UIControlStateNormal];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *randomButtonState = [defaults objectForKey:@"randomButton"];
    if (randomButtonState != nil) {
        NSNumber *repeatButtonState = [defaults objectForKey:@"repeatButton"];
        [_randomButton setSelected:[randomButtonState boolValue]];
        [_repeatButton setSelected:[repeatButtonState boolValue]];
    } else{
        [defaults setObject:[NSNumber numberWithBool:_randomButton.isSelected] forKey:@"randomButton"];
        [defaults setObject:[NSNumber numberWithBool:_repeatButton.isSelected] forKey:@"repeatButton"];
        [defaults synchronize];
        
    }
}


#pragma mark -
#pragma mark Player methods
- (void) prepareToPlay{
    NSInteger track = _tracksTableView.indexPathForSelectedRow.row;
    NSString *audioName = [[self.content objectAtIndex:track] valueForKey:@"name"];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, audioName];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSError *err;
    if (err) {
        NSLog(@"Error in initWithContentsOfURL: %@", [err localizedDescription]);
    }
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&err];
    if (err) {
        NSLog(@"Error in audioPlayer: %@", [err localizedDescription]);
    } else {
        _player.delegate = self;
//        _player.volume = 0.1;
        [_player prepareToPlay];
        
        Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
        if (playingInfoCenter) {
            MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
            NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      audioName, MPMediaItemPropertyTitle,
                                      [NSString stringWithFormat:@"%ld",track+1], MPMediaItemPropertyAlbumTrackNumber,
                                      [NSNumber numberWithDouble:_player.duration], MPMediaItemPropertyPlaybackDuration,
                                      [NSNumber numberWithDouble:_player.currentTime], MPNowPlayingInfoPropertyElapsedPlaybackTime,
                                      [NSString stringWithFormat:@"1.0"], MPNowPlayingInfoPropertyPlaybackRate,
                                      nil];
            center.nowPlayingInfo = songInfo;
        }
    }
}

- (void) playSong{
    [_player play];
    _progressUpdater = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(updateTrackTime) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationDidEnterBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
}

- (void) pauseSong{
    [_player pause];
    [_progressUpdater invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}


#pragma mark -
#pragma mark Button Actions
- (IBAction)randomAction:(id)sender {
    [_randomButton setSelected:!_randomButton.isSelected];
    [self calculateSongOrder];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:_randomButton.isSelected] forKey:@"randomButton"];
    [defaults synchronize];
}

- (IBAction)repeatAction:(id)sender {
    [_repeatButton setSelected:!_repeatButton.isSelected];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:_repeatButton.isSelected] forKey:@"repeatButton"];
    [defaults synchronize];
}

- (IBAction)backAction:(id)sender {
    [playedSongs removeObject:[NSNumber numberWithInteger:[_tracksTableView indexPathForSelectedRow].row]];
    [self goToRow:[self beforeSong]];
}

- (NSInteger) beforeSong{
    NSNumber *selectedTrack = [NSNumber numberWithInteger:[_tracksTableView indexPathForSelectedRow].row];
    NSInteger backTrack;
    
    if ([songsOrderToPlay count] > 0) {
        NSInteger trackPosition = [songsOrderToPlay indexOfObject:selectedTrack];
        backTrack = [[songsOrderToPlay objectAtIndex:(([songsOrderToPlay count]+trackPosition-1)%[songsOrderToPlay count])] integerValue];
    } else {
        backTrack = ([_content count]+[selectedTrack intValue]-1)%[_content count];
    }
    
    return backTrack;
}

- (IBAction)playAction:(id)sender {
    switch (songStatus) {
        case DOWNLOADABLE:
        case INCOMPLETE_DOWNLOAD:
            [self downloadTrack];
            songStatus = DOWNLOADING;
            break;
            
        case DOWNLOADING:
            if (downloadingAll) {
                downloadingAll = NO;
            }
            [self stopConnection];
            songStatus = INCOMPLETE_DOWNLOAD;
            break;
            
        case DOWNLOADED:
            [self playSong];
            songStatus = PLAYING;
            break;
            
        default:
            //playing case
            [self pauseSong];
            songStatus = DOWNLOADED;
            break;
    }
    [self customizeUI];
}

- (IBAction)nextAction:(id)sender {
    [playedSongs addObject:[NSNumber numberWithInteger:[_tracksTableView indexPathForSelectedRow].row]];
    [self goToRow:[self nextSong]];
}

- (NSInteger) nextSong{
    NSNumber *selectedTrack = [NSNumber numberWithInteger:[_tracksTableView indexPathForSelectedRow].row];
    NSInteger nextTrack;
    
    if ([songsOrderToPlay count] > 0) {
        NSInteger trackPosition = [songsOrderToPlay indexOfObject:selectedTrack];
        nextTrack = [[songsOrderToPlay objectAtIndex:((trackPosition+1)%[songsOrderToPlay count])] integerValue];
    } else {
        nextTrack = ([selectedTrack intValue]+1)%[_content count];
    }
    
    return nextTrack;
}

- (IBAction)downloadAllAction:(id)sender {
    downloadingAll = YES;
    [self goToRow:[[undownloadedSongs objectAtIndex:0] integerValue]];
}

- (IBAction)seekingTrack:(id)sender {
    [_player setCurrentTime:(_player.duration * _trackProgress.value)];
}


#pragma mark -
#pragma mark receive remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [self playSong];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self pauseSong];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (_player.playing) {
                    [self pauseSong];
                }
                else {
                    [self playSong];
                }
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [playedSongs addObject:[NSNumber numberWithInteger:[_tracksTableView indexPathForSelectedRow].row]];
                [self goToRow:[self nextSong]];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [playedSongs removeObject:[NSNumber numberWithInteger:[_tracksTableView indexPathForSelectedRow].row]];
                [self goToRow:[self beforeSong]];
                break;
            default:
                break;
        }
        [self customizeUI];
    }
}


#pragma mark -
#pragma mark UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.content count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *audioName = [[self.content objectAtIndex:indexPath.row] valueForKey:@"name"];
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = audioName;
    [_tracksTableView cellForRowAtIndexPath:indexPath].accessoryView = nil;
//    [self clearDeleteAccessoryWithIndexPath:indexPath];
    if ([FileUtils existAudio:audioName]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setSongStatus];
    [self showDeleteAccessory];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self clearDeleteAccessoryWithIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if ([cell accessoryType] == UITableViewCellAccessoryCheckmark) {
        [FileUtils removeTempAudioFile:cell.textLabel.text];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
}

- (void)accessoryAction:(id)sender event:(id)event {
    if (songStatus == DOWNLOADING) {
        [self stopConnection];
    }
    if (songStatus == PLAYING) {
        [self pauseSong];
    }
    [FileUtils removeTempAudioFile:[_tracksTableView cellForRowAtIndexPath:[_tracksTableView indexPathForSelectedRow]].textLabel.text];
    [_tracksTableView cellForRowAtIndexPath:[_tracksTableView indexPathForSelectedRow]].accessoryView = nil;
    [[_tracksTableView cellForRowAtIndexPath:[_tracksTableView indexPathForSelectedRow]] setAccessoryType:UITableViewCellAccessoryNone];
    
    NSInteger track = _tracksTableView.indexPathForSelectedRow.row;
    [undownloadedSongs addObject:[NSNumber numberWithInteger:track]];
    [downloadedSongs removeObject:[NSNumber numberWithInteger:track]];
    [_downloadAllBarButton setEnabled:YES];
    
    [self setSongStatus];
}


#pragma mark -
#pragma mark NSURLConnection delegate methods
- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse {
	NSLog(@"Connection received data, retain count");
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"Received response: %@", response);
	
    if (contentSize == 0) {
        NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
        contentSize = [httpResponse expectedContentLength];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSLog(@"Received %ld bytes of data", [data length]);
	
    [_receivedData appendData:data];
    [self updateProgress];
    
	NSLog(@"Received data is now %ld bytes", [_receivedData length]);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"Error receiving response: %@", error);
    [self saveTempFile];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"Succeeded! Received %ld bytes of data", [_receivedData length]);
    
    NSInteger track = _tracksTableView.indexPathForSelectedRow.row;
    [downloadedSongs addObject:[NSNumber numberWithInteger:track]];
    [undownloadedSongs removeObject:[NSNumber numberWithInteger:track]];
    [FileUtils saveDataToFile:_receivedData toAudio:downloadingAudioName];
    [self calculateSongOrder];
    if (!downloadingAll) {
        [self showDeleteAccessory];
        [self prepareToPlay];
        [self playSong];
        songStatus = PLAYING;
        [self customizeUI];
    } else{
        [[_tracksTableView cellForRowAtIndexPath:[_tracksTableView indexPathForSelectedRow]] setAccessoryType:UITableViewCellAccessoryCheckmark];
        if ([undownloadedSongs count] > 0) {
            [self goToRow:[[undownloadedSongs objectAtIndex:0] integerValue]];
        } else{
            [self showDeleteAccessory];
            downloadingAll = NO;
            [_downloadAllBarButton setEnabled:NO];
            [self goToRow:0];
        }
    }
}

- (void) stopConnection{
    [_connection cancel];
    _connection = nil;
    if (downloadingAudioName != nil) {
        [self saveTempFile];
    }
    downloadingAudioName = nil;
}

- (void) saveTempFile{
    [FileUtils saveDataToTempFile:_receivedData toAudio:downloadingAudioName withContentSize:contentSize];
}

- (void) downloadTrack {
    NSInteger track = _tracksTableView.indexPathForSelectedRow.row;
    downloadingAudioName = [[self.content objectAtIndex:_tracksTableView.indexPathForSelectedRow.row] valueForKey:@"name"];
    NSString *audioLink = [[self.content objectAtIndex:track] valueForKey:@"url"];
    
    NSMutableURLRequest* request = [NSMutableURLRequest
                                    requestWithURL:[NSURL URLWithString:audioLink]
                                    cachePolicy:NSURLRequestReloadIgnoringCacheData
                                    timeoutInterval:30.0];
    
    if ([_receivedData length] > 0) {
        NSString *range = [NSString stringWithFormat:@"bytes=%ld-%llu",[_receivedData length],contentSize];
        NSLog(@"range: %@", range);
        [request setValue:range forHTTPHeaderField:@"Range"];
    }
    
    _connection = [[NSURLConnection alloc]
                   initWithRequest:request
                   delegate:self
                   startImmediately:YES];
    
	if(!_connection) {
		NSLog(@"connection failed :(");
	} else {
		NSLog(@"connection succeeded  :)");
	}
}


#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {

    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self showDeleteAccessory];
}

@end

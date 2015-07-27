//
//  ViewController.m
//  MixerHost
//
//  Created by michael on 27/7/15.
//  Copyright (c) 2015 LeoEdu. All rights reserved.
//

#import "ViewController.h"
#import "MixerHostAudio.h"

NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";

@interface ViewController ()

@property (nonatomic, retain)    IBOutlet UIBarButtonItem    *playButton;

@property (nonatomic, retain)    IBOutlet UISwitch           *mixerBus0Switch;
@property (nonatomic, retain)    IBOutlet UISwitch           *mixerBus1Switch;

@property (nonatomic, retain)    IBOutlet UISlider           *mixerBus0LevelFader;
@property (nonatomic, retain)    IBOutlet UISlider           *mixerBus1LevelFader;
@property (nonatomic, retain)    IBOutlet UISlider           *mixerOutputLevelFader;

@property (nonatomic, retain)    MixerHostAudio              *audioObject;


- (IBAction) enableMixerInput:          (UISwitch *) sender;
- (IBAction) mixerInputGainChanged:     (UISlider *) sender;
- (IBAction) mixerOutputGainChanged:    (UISlider *) sender;
- (IBAction) playOrStop:                (id) sender;

- (void) handlePlaybackStateChanged: (id) notification;
- (void) initializeMixerSettingsToUI;
- (void) registerForAudioObjectNotifications;

@end

@implementation ViewController

# pragma mark -
# pragma mark User interface methods
// Set the initial multichannel mixer unit parameter values according to the UI state
- (void) initializeMixerSettingsToUI {
    
    // Initialize mixer settings to UI
    [_audioObject enableMixerInput: 0 isOn: _mixerBus0Switch.isOn];
    [_audioObject enableMixerInput: 1 isOn: _mixerBus1Switch.isOn];
    
    [_audioObject setMixerOutputGain: _mixerOutputLevelFader.value];
    
    [_audioObject setMixerInput: 0 gain: _mixerBus0LevelFader.value];
    [_audioObject setMixerInput: 1 gain: _mixerBus1LevelFader.value];
}

// Handle a change in the mixer output gain slider.
- (IBAction) mixerOutputGainChanged: (UISlider *) sender {
    
    [_audioObject setMixerOutputGain: (AudioUnitParameterValue) sender.value];
}

// Handle a change in a mixer input gain slider. The "tag" value of the slider lets this
//    method distinguish between the two channels.
- (IBAction) mixerInputGainChanged: (UISlider *) sender {
    
    UInt32 inputBus = sender.tag;
    [_audioObject setMixerInput: (UInt32) inputBus gain: (AudioUnitParameterValue) sender.value];
}


#pragma mark -
#pragma mark Audio processing graph control

// Handle a play/stop button tap
- (IBAction) playOrStop: (id) sender {
    
    if (_audioObject.isPlaying) {
        
        [_audioObject stopAUGraph];
        self.playButton.title = @"Play";
        
    } else {
        
        [_audioObject startAUGraph];
        self.playButton.title = @"Stop";
    }
}

// Handle a change in playback state that resulted from an audio session interruption or end of interruption
- (void) handlePlaybackStateChanged: (id) notification {
    
    [self playOrStop: nil];
}


#pragma mark -
#pragma mark Mixer unit control

// Handle a Mixer unit input on/off switch action. The "tag" value of the switch lets this
//    method distinguish between the two channels.
- (IBAction) enableMixerInput: (UISwitch *) sender {
    
    UInt32 inputBus = sender.tag;
    AudioUnitParameterValue isOn = (AudioUnitParameterValue) sender.isOn;
    
    [_audioObject enableMixerInput: inputBus isOn: isOn];
    
}


#pragma mark -
#pragma mark Remote-control event handling
// Respond to remote control events
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self playOrStop: nil];
                break;
                
            default:
                break;
        }
    }
}


#pragma mark -
#pragma mark Notification registration
// If this app's audio session is interrupted when playing audio, it needs to update its user interface
//    to reflect the fact that audio has stopped. The MixerHostAudio object conveys its change in state to
//    this object by way of a notification. To learn about notifications, see Notification Programming Topics.
- (void) registerForAudioObjectNotifications {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver: self
                           selector: @selector (handlePlaybackStateChanged:)
                               name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                             object: _audioObject];
}


#pragma mark -
#pragma mark Application state management

- (void) viewDidLoad {
    
    [super viewDidLoad];
    
    MixerHostAudio *newAudioObject = [[MixerHostAudio alloc] init];
    self.audioObject = newAudioObject;
    
    [self registerForAudioObjectNotifications];
    [self initializeMixerSettingsToUI];
}


// If using a nonmixable audio session category, as this app does, you must activate reception of
//    remote-control events to allow reactivation of the audio session when running in the background.
//    Also, to receive remote-control events, the app must be eligible to become the first responder.
- (void) viewDidAppear: (BOOL) animated {
    
    [super viewDidAppear: animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (BOOL) canBecomeFirstResponder {
    
    return YES;
}


- (void) didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void) viewWillDisppear: (BOOL) animated {
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    [super viewWillDisappear: animated];
}


- (void) viewDidUnload {
    
    self.playButton             = nil;
    self.mixerBus0Switch        = nil;
    self.mixerBus1Switch        = nil;
    self.mixerBus0LevelFader    = nil;
    self.mixerBus1LevelFader    = nil;
    self.mixerOutputLevelFader  = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                                                  object: _audioObject];
    
    self.audioObject            = nil;
    [super viewDidUnload];
}


- (void) dealloc {
    
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MixerHostAudioObjectPlaybackStateDidChangeNotification
                                                  object: _audioObject];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

@end

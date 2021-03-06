//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerViewController.h"

#import "NSBundle+RTSMediaPlayer.h"
#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerPlaybackButton.h"
#import "RTSTimeSlider.h"
#import "RTSVolumeView.h"

#import <libextobjc/EXTScope.h>

@interface RTSMediaPlayerViewController () <RTSMediaPlayerControllerDataSource>

@property (nonatomic, weak) id<RTSMediaPlayerControllerDataSource> dataSource;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (weak) IBOutlet RTSMediaPlayerPlaybackButton *playPauseButton;
@property (weak) IBOutlet RTSTimeSlider *timeSlider;
@property (weak) IBOutlet RTSVolumeView *volumeView;
@property (weak) IBOutlet UIButton *liveButton;

@property (weak) IBOutlet UIActivityIndicatorView *loadingAcitivityIndicatorView;
@property (weak) IBOutlet UILabel *loadingLabel;

@property (weak) IBOutlet NSLayoutConstraint *valueLabelWidthConstraint;
@property (weak) IBOutlet NSLayoutConstraint *timeLeftValueLabelWidthConstraint;

@end

@implementation RTSMediaPlayerViewController

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:self];
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	if (!(self = [super initWithNibName:@"RTSMediaPlayerViewController" bundle:[NSBundle RTSMediaPlayerBundle]]))
		return nil;
	
	_dataSource = dataSource;
	_identifier = identifier;
	
	return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mediaPlayerPlaybackStateDidChange:)
												 name:RTSMediaPlayerPlaybackStateDidChangeNotification
											   object:self.mediaPlayerController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mediaPlayerDidShowControlOverlays:)
												 name:RTSMediaPlayerDidShowControlOverlaysNotification
											   object:self.mediaPlayerController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mediaPlayerDidHideControlOverlays:)
												 name:RTSMediaPlayerDidHideControlOverlaysNotification
											   object:self.mediaPlayerController];
	
	[self.mediaPlayerController setDataSource:self.dataSource];
	
	[self.mediaPlayerController attachPlayerToView:self.view];
	[self.mediaPlayerController playIdentifier:self.identifier];
	
	[self.liveButton setTitle:RTSMediaPlayerLocalizedString(@"Back to live", nil) forState:UIControlStateNormal];
	self.liveButton.alpha = 0.f;
	
	self.liveButton.layer.borderColor = [UIColor whiteColor].CGColor;
	self.liveButton.layer.borderWidth = 1.f;
	
	// Hide the time slider while the stream type is unknown (i.e. the needed slider label size cannot be determined)
	[self setTimeSliderHidden:YES];
	
	@weakify(self)
	[self.mediaPlayerController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., 5.) queue:NULL usingBlock:^(CMTime time) {
		@strongify(self)
		
		if (self.mediaPlayerController.streamType != RTSMediaStreamTypeUnknown) {
			CGFloat labelWidth = (CMTimeGetSeconds(self.mediaPlayerController.timeRange.duration) >= 60. * 60.) ? 56.f : 45.f;
			self.valueLabelWidthConstraint.constant = labelWidth;
			self.timeLeftValueLabelWidthConstraint.constant = labelWidth;
			
			if (self.mediaPlayerController.playbackState != RTSMediaPlaybackStateSeeking) {
				[self updateLiveButton];
			}
			
			[self setTimeSliderHidden:NO];
		}
		else {
			[self setTimeSliderHidden:YES];
		}
	}];
}

- (void)setTimeSliderHidden:(BOOL)hidden
{
	self.timeSlider.timeLeftValueLabel.hidden = hidden;
	self.timeSlider.valueLabel.hidden = hidden;
	self.timeSlider.hidden = hidden;
	
	self.loadingAcitivityIndicatorView.hidden = !hidden;
	if (hidden) {
		[self.loadingAcitivityIndicatorView startAnimating];
	}
	else {
		[self.loadingAcitivityIndicatorView stopAnimating];
	}
	self.loadingLabel.hidden = !hidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleDefault;
}

#pragma mark - UI

- (void)updateLiveButton
{
	if (self.mediaPlayerController.streamType == RTSMediaStreamTypeDVR) {
		[UIView animateWithDuration:0.2 animations:^{
			self.liveButton.alpha = self.timeSlider.live ? 0.f : 1.f;
		}];
	}
	else {
		self.liveButton.alpha = 0.f;
	}
}

#pragma mark - RTSMediaPlayerControllerDataSource

- (void)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	  contentURLForIdentifier:(NSString *)identifier
			completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	completionHandler([NSURL URLWithString:self.identifier], nil);
}



#pragma mark - Notifications

- (void)mediaPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	RTSMediaPlayerController *mediaPlayerController = notification.object;
	if (mediaPlayerController.playbackState == RTSMediaPlaybackStateEnded) {
		[self dismiss:nil];
	}
}

- (void)mediaPlayerDidShowControlOverlays:(NSNotification *)notification
{
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)mediaPlayerDidHideControlOverlays:(NSNotification *)notificaiton
{
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender
{
	[self.mediaPlayerController reset];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goToLive:(id)sender
{
	[UIView animateWithDuration:0.2 animations:^{
		self.liveButton.alpha = 0.f;
	}];
	
	CMTimeRange timeRange = self.mediaPlayerController.timeRange;
	if (CMTIMERANGE_IS_INDEFINITE(timeRange) || CMTIMERANGE_IS_EMPTY(timeRange)) {
		return;
	}
	
	[self.mediaPlayerController playAtTime:CMTimeRangeGetEnd(timeRange)];
}

- (IBAction)seek:(id)sender
{
	[self updateLiveButton];
}

@end

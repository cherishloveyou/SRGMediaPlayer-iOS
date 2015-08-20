//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>
#import <SRGMediaPlayer/RTSMediaPlayerController.h>

/**
 *  View displaying playback errors. Simply install an instance somewhere onto your custom player interface and bind to 
 *  the media player controller for which errors must be reported. Add a label and bind it to the text label property to 
 *  display the error message.
 * 
 *  The view will be automatically shown when an error occurs, and hidden otherwise.
 */
@interface RTSMediaFailureOverlayView : UIView

/**
 *  The media player controller for which errors must be reported
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

/**
 *  The label which will be used to display error messages
 */
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end

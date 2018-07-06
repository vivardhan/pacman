//
//  ViewController.h
//  MacSpell
//
//  Created by Vivardhan Kanoria on 6/25/15.
//  Copyright (c) 2015 Self. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppKit/AppKit.h>
#import "VideoCaptureViewController.h"
//#import "GLImageView.h"
//#include "VisionPlatform.hpp"
//#include "DataManager.hpp"
//#include "DataDebug.hpp"
//#include "Helper.hpp"
//#include "RegressionRunnerJson.hpp"

@interface ViewController : VideoCaptureViewController {}

enum IMAGE_TYPE {
    NONE, /* used for pressButton */
    ORIGINAL,
    CANNY,
    WARPED,
    NON_WARPED
};

enum CAPTURE_TYPE {
    OFF,
    ONE,
    ONE_SERVER,
    CONTINUOUS
};

struct SetupParameters {
    bool setup;
    bool calibrationBank;
    bool useDefaultOnly;
    int resolution;
};

@property IMAGE_TYPE currentImage;
@property IMAGE_TYPE pressedButton;
@property bool lockExposure;
@property bool lockWhiteBalance;
@property bool findBright;
@property CAPTURE_TYPE captureFrame;

@property bool regressionRunnning;
@property SetupParameters setupParameters;

@property (retain, nonatomic) IBOutlet NSTextFieldCell *display;
@property (retain, nonatomic) IBOutlet NSTextFieldCell *detections;

@property (retain, nonatomic) IBOutlet NSButton *cannyBtn;
@property (retain, nonatomic) IBOutlet NSButton *warpedBtn;
@property (retain, nonatomic) IBOutlet NSButton *nonWarpedBtn;
@property (retain, nonatomic) IBOutlet NSButton *originalBtn;
@property (retain, nonatomic) IBOutlet NSButton *recordBtn;
@property (retain, nonatomic) IBOutlet NSButton *captureBtn;
@property (retain, nonatomic) IBOutlet NSButton *lockExposureBtn;
@property (retain, nonatomic) IBOutlet NSButton *lockWhiteBalanceBtn;
@property (retain, nonatomic) IBOutlet NSButton *findBrightBtn;
@property (retain, nonatomic) IBOutlet NSButton *RunRegressionBtn;
@property (retain, nonatomic) IBOutlet NSWindow *window;

@property (nonatomic, strong) NSArray *modeArray;
@property (assign) IBOutlet NSPopUpButtonCell *modePicker;

//@property (strong, nonatomic) CMMotionManager *manager;

-(IBAction)toggleCanny:(id)sender;
-(IBAction)toggleWarped:(id)sender;
-(IBAction)toggleNonWarped:(id)sender;
-(IBAction)toggleOriginal:(id)sender;
-(IBAction)saveFrame: (id)sender;
-(IBAction)saveOneFrame: (id)sender;
-(IBAction)toggleLockExposure;
-(IBAction)toggleLockWhiteBalance;
-(IBAction)toggleFindBright;

-(IBAction)selectMode:(id)sender;
-(IBAction)useSetup:(id)sender;
-(IBAction)useCalibration:(id)sender;
-(IBAction)useRegression:(id)sender;


@end

@interface NSHost (Hardware)
+ (NSString*)hardwareString;
@end

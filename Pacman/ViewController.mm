//
//  ViewController.m
//  MacSpell
//
//  Created by Vivardhan Kanoria on 6/25/15.
//  Copyright (c) 2015 Self. All rights reserved.
//

#include <random>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#include <Carbon/Carbon.h>

//#import "CaptureHistory.h"
//#import "JsonBuilder.h"
//#import "UploadQueue.h"
#import "ViewController.h"

using namespace cv;

@interface ViewController ()
@property NSDictionary *modes;
//@property JsonBuilder *jb;
- (void)setLabel:(NSString *)label;
@end

@implementation NSHost (Hardware)

+ (NSString *)hardwareString {
    NSString *result = @"MacBad";
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len) {
        NSMutableData *data = [NSMutableData dataWithLength:len];
        sysctlbyname("hw.model", [data mutableBytes], &len, NULL, 0);
        result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return result;
}

@end

@implementation ViewController
@synthesize display;
@synthesize detections;
@synthesize currentImage;
@synthesize lockExposure;
@synthesize findBright;
@synthesize lockWhiteBalance;
@synthesize captureFrame;

@synthesize pressedButton;

@synthesize regressionRunnning;
@synthesize setupParameters;

@synthesize cannyBtn;
@synthesize warpedBtn;
@synthesize nonWarpedBtn;
@synthesize originalBtn;
@synthesize captureBtn;
@synthesize lockExposureBtn;
@synthesize lockWhiteBalanceBtn;
@synthesize findBrightBtn;
@synthesize RunRegressionBtn;
@synthesize window;

@synthesize modePicker;
@synthesize modeArray;

std::chrono::steady_clock::time_point _startTime;
bool _gameStarted = NO;
std::random_device rd{};
std::mt19937 _gen = std::mt19937(rd());

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.captureGrayscale = NO;
        self.camera = 0;
        self.qualityPreset = AVCaptureSessionPresetHigh;
    }

    modeArray =
        [[NSArray alloc] initWithObjects:@"None", @"Kaleidoscope", @"DrawingDone", @"Tangrams", @"Words", @"Monster",
                                         @"Paper", @"Newton", @"Coins", @"Numbers", @"SecretCards", @"ColorCoins", nil];

    pressedButton = NONE;
    currentImage = ORIGINAL;

    lockExposure = false;
    lockWhiteBalance = false;
    findBright = true;

    captureFrame = OFF;

    regressionRunnning = false;

//    Profile::Instance().SetReportFreqency(60);

    //    self.manager = [[CMMotionManager alloc] init];
    //
    //    self.manager.deviceMotionUpdateInterval = 0.01;  // 100 Hz
    //    [self.manager startDeviceMotionUpdates];

    char const *appPath = [[[NSBundle mainBundle] bundlePath] UTF8String];
//    VisionPlatform::SetString(VisionParameters::PARAMETER_FOLDER, (std::string) appPath + "/../Resources");

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    std::string folder = documentsDirectory.fileSystemRepresentation;
//    VisionPlatform::SetString(VisionParameters::OUTPUT_FOLDER, folder);

    // https://support.apple.com/en-us/HT201300
    std::string deviceString = (std::string)([[NSHost hardwareString] UTF8String]);
//    VisionPlatform::SetString(VisionParameters::DEVICE_STRING, deviceString);

//    VisionPlatform::SetFloat(VisionParameters::MOTION_ESTIMATION_THRESHOLD, 0.7f);

    setupParameters.setup = false;
    setupParameters.calibrationBank = false;
    setupParameters.resolution = 50;
    [self restoreSetupParameters];

//    [self handleNewMode];

//    std::cout << "VisionPlatform:" << VisionPlatform::version() << std::endl;

    return self;
}

- (void)setLabel:(NSString *)label {
    [display setStringValue:label];
}

//- (void)drawDetections:(const std::vector<Block> &)matches {
//    NSString *text = [NSString stringWithFormat:@""];
//
//    std::vector<int> ids;
//    for (const Block &bl : matches) {
//        ids.push_back(bl.id);
//    }
//    std::sort(ids.begin(), ids.end());
//
//    for (int id : ids) {
//        text = [NSString stringWithFormat:@"%@   %@", text, [NSString stringWithFormat:@"%d ", id]];
//    }
//    [detections setStringValue:text];
//}

- (void)viewWillDisappear:(BOOL)animated {
    [_captureSession stopRunning];
}

- (void)viewWillAppear:(BOOL)animated {
    [_captureSession startRunning];
}

enum DeviceBody {
    UNDEFINED = 0,
    IPAD_234 = 1,
    IPAD_AIR = 2,
    IPAD_MINI = 3,
    IPAD_AIR2 = 4,
};

DeviceBody GetDeviceBody() {
    NSString *hardware = [NSHost hardwareString];
//    std::cout << "ipad = " << (std::string)([hardware UTF8String]) << std::endl;

    if ([hardware isEqualToString:@"iPad1,1"]) return IPAD_234;   // iPad (WiFi)
    if ([hardware isEqualToString:@"iPad1,2"]) return IPAD_234;   // iPad 3G
    if ([hardware isEqualToString:@"iPad2,1"]) return IPAD_234;   // iPad 2 (WiFi)
    if ([hardware isEqualToString:@"iPad2,2"]) return IPAD_234;   // iPad 2 (GSM)
    if ([hardware isEqualToString:@"iPad2,3"]) return IPAD_234;   // iPad 2 (CDMA)
    if ([hardware isEqualToString:@"iPad2,4"]) return IPAD_234;   // iPad 2 (WiFi Rev. A)
    if ([hardware isEqualToString:@"iPad2,5"]) return IPAD_MINI;  // iPad Mini (WiFi)
    if ([hardware isEqualToString:@"iPad2,6"]) return IPAD_MINI;  // iPad Mini (GSM)
    if ([hardware isEqualToString:@"iPad2,7"]) return IPAD_MINI;  // iPad Mini (CDMA)
    if ([hardware isEqualToString:@"iPad3,1"]) return IPAD_234;   // iPad 3 (WiFi)
    if ([hardware isEqualToString:@"iPad3,2"]) return IPAD_234;   // iPad 3 (CDMA)
    if ([hardware isEqualToString:@"iPad3,3"]) return IPAD_234;   // iPad 3 (Global)
    if ([hardware isEqualToString:@"iPad3,4"]) return IPAD_234;   // iPad 4 (WiFi)
    if ([hardware isEqualToString:@"iPad3,5"]) return IPAD_234;   // iPad 4 (CDMA)
    if ([hardware isEqualToString:@"iPad3,6"]) return IPAD_234;   // iPad 4 (Global)
    if ([hardware isEqualToString:@"iPad4,1"]) return IPAD_AIR;   // iPad Air (WiFi)
    if ([hardware isEqualToString:@"iPad4,2"]) return IPAD_AIR;   // iPad Air (WiFi+GSM)
    if ([hardware isEqualToString:@"iPad4,3"]) return IPAD_AIR;   // iPad Air (WiFi+CDMA)
    if ([hardware isEqualToString:@"iPad4,4"]) return IPAD_MINI;  // iPad Mini Retina (WiFi)
    if ([hardware isEqualToString:@"iPad4,5"]) return IPAD_MINI;  // iPad Mini Retina (WiFi+CDMA)
    if ([hardware isEqualToString:@"iPad4,6"]) return IPAD_MINI;  // iPad Mini Retina  New
    if ([hardware isEqualToString:@"iPad4,7"]) return IPAD_MINI;  // iPad Mini Retina  New
    if ([hardware isEqualToString:@"iPad4,8"]) return IPAD_MINI;  // iPad Mini Retina  New
    if ([hardware isEqualToString:@"iPad4,9"]) return IPAD_MINI;  // iPad Mini Retina  New
    if ([hardware isEqualToString:@"iPad5,1"]) return IPAD_AIR2;  // iPad Air 2
    if ([hardware isEqualToString:@"iPad5,2"]) return IPAD_AIR2;  // iPad Air 2
    if ([hardware isEqualToString:@"iPad5,3"]) return IPAD_AIR2;  // iPad Air 2
    if ([hardware isEqualToString:@"iPad5,4"]) return IPAD_AIR2;  // iPad Air 2

    return UNDEFINED;
}

- (void)sendToServerWithFilename:(std::string)filename {
    NSString *nsFilename = [NSString stringWithUTF8String:filename.c_str()];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *bmpFilename =
        [documentsDirectory stringByAppendingPathComponent:[nsFilename stringByAppendingString:@"_0.bmp"]];
    NSString *jsonFilename =
        [documentsDirectory stringByAppendingPathComponent:[nsFilename stringByAppendingString:@"_0.json"]];

    NSData *bmpData = [NSData dataWithContentsOfFile:bmpFilename];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonFilename];

    if (jsonFilename == nil || bmpData == nil) {
        //        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not load files" delegate:nil
        //                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Error"];
        [alert setInformativeText:@"Could not load files."];
        [alert setAlertStyle:NSWarningAlertStyle];
        //        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }

    NSString *URL = @"https://tools.playosmo.com/upload/sample?user_message=spell&definition_format=json_v1";

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]];

    NSString *authValue = @"Basic c3BlbGw6U3BlbEw=";
    [request setValue:authValue forHTTPHeaderField:@"X-VisionOsmo-Authorization"];

    [request setHTTPMethod:@"POST"];

    NSString *boundary = @"--I--LOVE--CHOUCROUTE--";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"sample\"; filename=\"sample.bmp\"\r\n"
                         dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/bmp\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:bmpData];

    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"definition\"; filename=\"sample.json\"\r\n"
                         dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/json\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:jsonData];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPBody:body];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

                               NSLog(@"sendAsynchronousRequest: %@", [connectionError localizedDescription]);
                               // NSString *content = [[NSString alloc] initWithData:data
                               // encoding:NSUTF8StringEncoding];
                               // NSLog(content);

                               if (connectionError == nil && ((NSHTTPURLResponse *) response).statusCode == 200) {
                                   //            [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Files sent."
                                   //            delegate:nil
                                   //                              cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                   NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                                   [alert addButtonWithTitle:@"OK"];
                                   [alert setMessageText:@"Success"];
                                   [alert setInformativeText:@"Files sent."];
                                   [alert setAlertStyle:NSWarningAlertStyle];
                                   //            [alert beginSheetModalForWindow:[self window] modalDelegate:self
                                   //            didEndSelector:nil contextInfo:nil];
                               } else {
                                   //            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Probleming send
                                   //            the files" delegate:nil
                                   //                              cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                   NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                                   [alert addButtonWithTitle:@"OK"];
                                   [alert setMessageText:@"Error"];
                                   [alert setInformativeText:@"Problem sending files."];
                                   [alert setAlertStyle:NSWarningAlertStyle];
                                   //            [alert beginSheetModalForWindow:[self window] modalDelegate:self
                                   //            didEndSelector:nil contextInfo:nil];
                               }
                           }];
}

- (void)startGame {
    
    CGEventRef dummy = CGEventCreate(NULL);
    CGPoint origin = CGEventGetLocation(dummy);
    CFRelease(dummy);
    
    int posx = 900;
    int posy = 530;
    
    // Move to posxXposy
    CGEventRef move1 = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, CGPointMake(posx, posy), kCGMouseButtonLeft );
    CGEventPost(kCGHIDEventTap, move1);
    CFRelease(move1);
    
    // Left button down at posxXposy
    CGEventRef click1_down = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGPointMake(posx, posy), kCGMouseButtonLeft);
    // Left button up at posxXposy
    CGEventRef click1_up = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, CGPointMake(posx, posy), kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, click1_down);
    CGEventPost(kCGHIDEventTap, click1_up);
    CGEventPost(kCGHIDEventTap, click1_down);
    CGEventPost(kCGHIDEventTap, click1_up);
    
    // Release the events
    CFRelease(click1_up);
    CFRelease(click1_down);
    
    CGEventRef move2 = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, origin, kCGMouseButtonLeft );
    CGEventPost(kCGHIDEventTap, move2);
    CFRelease(move2);
    
    _gameStarted = YES;
}

- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)orientation {
//    [self handleNewMode];
    if (_gameStarted == NO) {
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - _startTime);
        if (elapsed.count() >= 2000) {
            [self startGame];
            _startTime = std::chrono::steady_clock::now();
        } else {
            return;
        }
    }
    
    
    if (std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - _startTime).count() > 2000) {
        auto dis = std::uniform_int_distribution<int>{0, 4};
        switch (dis(_gen)) {
            case 0:
                [self pressKey:kVK_UpArrow];
                break;
            case 1:
                [self pressKey:kVK_DownArrow];
                break;
            case 2:
                [self pressKey:kVK_RightArrow];
                break;
            case 3:
                [self pressKey:kVK_LeftArrow];
                break;
            default:
                break;
        }
        _startTime = std::chrono::steady_clock::now();
    }

    if (pressedButton != NONE) {
        /* We use this trick to make sure everything is modified synchronously */
        currentImage = pressedButton;
        pressedButton = NONE;
    }

    //    if ([_captureDevice lockForConfiguration:nil] == YES) {
    //
    //        // exposure
    //        if (lockExposure) {
    //            if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeLocked]) {
    //                [_captureDevice setExposureMode:AVCaptureExposureModeLocked];
    //            }
    //        }
    //        else {
    //            if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
    //                [_captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    //            }
    //        }
    //
    //        // white balance
    //        if (lockWhiteBalance) {
    //            if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
    //                [_captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
    //            }
    //        }
    //        else {
    //            if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
    //            {
    //                [_captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    //            }
    //        }
    //
    //        [_captureDevice unlockForConfiguration];
    //    }

//    VisionPlatform::SetBool(VisionParameters::DEBUG_MODE, currentImage != ORIGINAL);
//
//    VisionPlatform::VisionInput vi;
//    vi.bgra640x480 = mat;
//    vi.pitch = 0.0f;
    //    vi.pitch = self.manager.deviceMotion.attitude.pitch *180.0/CV_PI;
    //    vi.roll  = self.manager.deviceMotion.attitude.roll  *180.0/CV_PI;
//    vi.hints = "";

//    VisionPlatform::SetVisionInput(vi);
//    VisionPlatform::Run();
//    const VisionPlatform::VisionOutput vo = VisionPlatform::GetVisionOutput();

    // dump mat for debugging
//    const std::vector<Block> &matchedBlocks = vo.blocks;
//    cv::Mat im;
//
//    switch (currentImage) {
//        case WARPED:
//            if (VisionPlatform::GetRecognitionMode() != RECOGNITION_MODE::NONE) {
//                im = DataDebug::Instance().getDebugWarped();
//                cv::putText(im, "Warped", cv::Point(im.cols / 2, 20), CV_FONT_HERSHEY_COMPLEX_SMALL, 1, Helper::Black);
//            } else {
//                std::cout << "Please select a mode!" << std::endl;
//            }
//            break;
//        case CANNY:
//            if (VisionPlatform::GetRecognitionMode() != RECOGNITION_MODE::NONE) {
//                im = DataDebug::Instance().getDebugImg();
//                cv::putText(im, "Canny", cv::Point(im.cols / 2, 20), CV_FONT_HERSHEY_COMPLEX_SMALL, 1, Helper::Black);
//            } else {
//                std::cout << "Please select a mode!" << std::endl;
//            }
//            break;
//        case NON_WARPED:
//            im = DataManager::Instance()->getBgraNonWarpedNonCropped();
//            cv::putText(im, "Non warped", cv::Point(im.cols / 2, 20), CV_FONT_HERSHEY_COMPLEX_SMALL, 1, Helper::Black);
//        default:
//            break;
//    }
//
//    if (!im.empty()) {
//        cv::imshow("Debug", im);
//        cv::waitKey(1);
//    } else {
//        cv::destroyAllWindows();
//    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

//    bool shouldCapture = captureFrame != OFF;

    std::string filename;
//    if (shouldCapture) {
//        filename = VisionPlatform::DumpDebugFrames(documentsDirectory.fileSystemRepresentation);
//    }

    if (captureFrame == ONE) {
        captureFrame = OFF;
    }

    if (captureFrame == ONE_SERVER) {
        [self sendToServerWithFilename:filename];
        captureFrame = OFF;
    }

//    dispatch_sync(dispatch_get_main_queue(), ^{
//        [self drawDetections:matchedBlocks];
//        [self setLabel:[NSString stringWithFormat:@"fps = %.1f; %s, %s", self.fps,
//                                                  vo.setupAndCalibration.calibrationBankString.c_str(),
//                                                  (VisionPlatform::GetRecognitionMode() ==
//                                                   RECOGNITION_MODE::CHESSBOARD_CALIBRATION) ?
//                                                      "In Progress" :
//                                                      "Done!"]];
//    });

    //    [self setExposurePointOfInterest];
}

- (void)RunRegression {
    regressionRunnning = true;

    [_captureSession stopRunning];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

//    VisionPlatform::SetBool(VisionParameters::REGRESSION_MODE, true);

//    RegressionRunnerJson runner(documentsDirectory.fileSystemRepresentation, "regression.xml", true, false);

    // Sleep 5 sec to easily locate on profiling screen
    [NSThread sleepForTimeInterval:5.0f];

//    runner.Run();

    // Sleep 5 sec to easily locate on profiling screen
    [NSThread sleepForTimeInterval:5.0f];

//    VisionPlatform::SetBool(VisionParameters::REGRESSION_MODE, false);

//    Profile::Instance().SetReportFreqency(60);
//    Profile::Instance().Clear();

    [_captureSession startRunning];

    regressionRunnning = false;
}

- (IBAction)toggleCanny:(id)sender {
    pressedButton = CANNY;
    //    [self loadImageView];
}

- (IBAction)toggleWarped:(id)sender {
    pressedButton = WARPED;
    //    [self loadImageView];
}

- (IBAction)toggleNonWarped:(id)sender {
    pressedButton = NON_WARPED;
    //    [self loadImageView];
}

- (IBAction)toggleOriginal:(id)sender {
    pressedButton = ORIGINAL;
    //    [self unloadImageView];
}

- (void)outputCameraState {
//    std::cout << "Camera state:" << std::endl;
//    std::cout << "\tlockWhiteBalance = " << lockWhiteBalance << std::endl;
//    std::cout << "\tlockExposure     = " << lockExposure << std::endl;
//    std::cout << "\tfindBright       = " << findBright << std::endl;
//    std::cout << std::endl;
}

- (void)toggleLockWhiteBalance {
    lockWhiteBalance = !lockWhiteBalance;
    [self outputCameraState];
}

- (void)toggleLockExposure {
    lockExposure = !lockExposure;
    [self outputCameraState];
}

- (void)toggleFindBright {
    findBright = !findBright;
    [self outputCameraState];
}

- (IBAction)selectMode:(id)sender {
    NSMenuItem *selectedItem = [self.modePicker selectedItem];
    [self setModeFromString:selectedItem.title];
}

- (IBAction)useSetup:(id)sender {
//    bool setup = VisionPlatform::GetBool(VisionParameters::RUN_SETUP);
//    VisionPlatform::SetInt(VisionParameters::SETUP_RESOLUTION, 1);
//    VisionPlatform::SetBool(VisionParameters::RUN_SETUP, !setup);
}

- (IBAction)useCalibration:(id)sender {
//    VisionPlatform::SetRecognitionMode(RECOGNITION_MODE::CHESSBOARD_CALIBRATION);

//    cv::Rect stand = VisionPlatform::GetVisionOutput().setupAndCalibration.standRect;
//    if (stand.x == -1) {
//        std::cout << "Please activate setup!" << std::endl;
//        return;
//    }
}

- (void)setSetupParametersForCapture {
//    setupParameters.setup = VisionPlatform::GetBool(VisionParameters::RUN_SETUP);
//    setupParameters.calibrationBank = VisionPlatform::GetBool(VisionParameters::CALIBRATION_BANK);
//    setupParameters.resolution = VisionPlatform::GetInt(VisionParameters::SETUP_RESOLUTION);
//    setupParameters.useDefaultOnly = VisionPlatform::GetBool(VisionParameters::USE_ONLY_DEFAULT_CALIBRATION);
//
//    VisionPlatform::SetBool(VisionParameters::RUN_SETUP, true);
//    VisionPlatform::SetBool(VisionParameters::CALIBRATION_BANK, true);
//    VisionPlatform::SetBool(VisionParameters::USE_ONLY_DEFAULT_CALIBRATION, false);
//    VisionPlatform::SetInt(VisionParameters::SETUP_RESOLUTION, 1);
//    if (mode == RECOGNITION_MODE::NONE) {
//        mode = RECOGNITION_MODE::SETUP;
//    }
}

- (void)restoreSetupParameters {
//    VisionPlatform::SetBool(VisionParameters::RUN_SETUP, setupParameters.setup);
//    VisionPlatform::SetBool(VisionParameters::CALIBRATION_BANK, setupParameters.calibrationBank);
//    VisionPlatform::SetInt(VisionParameters::SETUP_RESOLUTION, setupParameters.resolution);
//    VisionPlatform::SetBool(VisionParameters::USE_ONLY_DEFAULT_CALIBRATION, setupParameters.useDefaultOnly);
//
//    if (mode == RECOGNITION_MODE::SETUP) {
//        mode = RECOGNITION_MODE::NONE;
//    }
}

- (void)saveFrame:(id)sender {
    if (captureFrame == OFF) {
        captureFrame = CONTINUOUS;
    } else {
        captureFrame = OFF;
    }

    if (captureFrame == CONTINUOUS) {
        [self setSetupParametersForCapture];
        [sender setTitle:@"STOP Capture"];
    } else {
        [self restoreSetupParameters];
        [sender setTitle:@"Start Capture"];
    }
}

- (void)saveOneFrame:(id)sender {
    captureFrame = ONE;

    [self setSetupParametersForCapture];
}

- (IBAction)saveOneFrameToServer:(id)sender {
    captureFrame = ONE_SERVER;

    [self setSetupParametersForCapture];
}

- (IBAction)useRegression:(id)sender {
    if ([self regressionRunnning] == false) {
        [self RunRegression];
    }
}

- (void)InitCardDb {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_captureSession startRunning];
    
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    NSString *path = [[NSBundle mainBundle] pathForResource:@"pacman" ofType:@"html"];
    task.arguments = @[path];
    task.standardOutput = pipe;
    
    [task launch];
    _startTime = std::chrono::steady_clock::now();
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"open returned:\n%@", output);
    
//    CGEventRef event1, event2, event3, event4;
//    event1 = CGEventCreateKeyboardEvent (NULL, kVK_UpArrow, true);
//    CGEventPost(kCGSessionEventTap, event1);
//    CFRelease(event1);

    [modePicker removeAllItems];
    [modePicker addItemsWithTitles:modeArray];
}

-(void)pressKey: (CGKeyCode)key {
    CGEventRef event;
    event = CGEventCreateKeyboardEvent (NULL, key, true);
    CGEventPost(kCGSessionEventTap, event);
    CFRelease(event);
}

- (void)viewDidUnload {
    [self setDisplay:nil];
    [self setDetections:nil];
    [self setCannyBtn:nil];
    [self setWarpedBtn:nil];
    [self setOriginalBtn:nil];
    [self setRecordBtn:nil];
    [super viewDidUnload];
    [_captureSession stopRunning];
    // Release any retained subviews of the main view.
}

- (void)dealloc {
    [display release];
    [detections release];
    [cannyBtn release];
    [warpedBtn release];
    [originalBtn release];
    //    [imageView release];
    [_recordBtn release];
    [super dealloc];
}

@end

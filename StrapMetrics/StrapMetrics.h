//
//  StrapMetrics.h
//
//  Created by scald on 6/30/14.
//  Copyright (c) 2014 strap. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StrapMetrics : UIResponder <UIApplicationDelegate,NSURLConnectionDelegate> {
    NSMutableData *responseData;
}

+(void) strap_init;
+(void) strap_api_log: (NSDictionary*)data minReadings:(int)min_readings logParameters:(NSDictionary*)log_parameters serialNo:(NSString*)serial;
+(bool) strap_api_can_handle_msg: (NSDictionary*) data;
+(void) strap_api_cleanup: (NSTimer *) theTimer logParameters:(NSDictionary *) params;
+ (NSDictionary*) strap_api_clone:(NSDictionary*) obj;

@property (strong, nonatomic) UIWindow *window;



@end

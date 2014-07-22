//
//  StrapMetrics.m
//
//  Created by scald on 6/30/14.
//  Copyright (c) 2014 strap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StrapMetrics.h"
#import "CJSONSerializer.h"

@interface StrapMetrics () <UIApplicationDelegate,NSURLConnectionDelegate>

+(void) strap_init;
+(void) strap_api_log: (NSDictionary*)data minReadings:(int)min_readings logParameters:(NSDictionary*)log_parameters serialNo:(NSString*)serial;
+(bool) strap_api_can_handle_msg: (NSDictionary*) data;
+(void) strap_api_cleanup: (NSTimer *) theTimer logParameters: (NSDictionary *) params;
+ (NSDictionary*) strap_api_clone:(NSDictionary*) obj;


@end

@implementation StrapMetrics

NSMutableArray *tmpStore;
NSTimer *strap_api_timer_send;

int strap_api_num_samples = 10;
NSString *strap_api_url = @"https://api.straphq.com/create/visit/with/";

NSDictionary* get_strap_api_const() {
    return @{
             @"KEY_OFFSET":@48000,
             @"T_TIME_BASE":@1000,
             @"T_TS":@1,
             @"T_X":@2,
             @"T_Y":@3,
             @"T_Z":@4,
             @"T_DID_VIBRATE":@5,
             @"T_ACTIVITY":@2000,
             @"T_LOG":@3000
             };
}

+ (void) strap_init {
    tmpStore = [[NSMutableArray alloc] init];
}

+ (bool) strap_api_can_handle_msg: (NSDictionary*) data {
    
    NSDictionary *sac = get_strap_api_const();
    
    if( [data objectForKey:@([sac[@"KEY_OFFSET"] intValue] + [sac[@"T_ACTIVITY"] intValue])] ) {
        return true;
    }
    
    if( [data objectForKey:@([sac[@"KEY_OFFSET"] intValue] + [sac[@"T_LOG"] intValue])]) {
        return true;
    }
    
    return false;
}

+ (NSDictionary*) strap_api_clone:(NSDictionary*) obj {
    if (nil == obj || [obj isKindOfClass:[NSDictionary class]]) {
        return obj;
    }
    
    NSDictionary *copy = [[NSDictionary alloc] init];
    
    for (NSString *attr in obj) {
        if ([obj objectForKey:attr]) {
            [copy setValue:obj[attr] forKey:attr];
        };
    }
    
    return copy;
}


+ (NSMutableArray*)strap_api_convAcclData:(NSDictionary *) data {
    NSDictionary *sac = get_strap_api_const();
    
    NSMutableArray *convData = [[NSMutableArray alloc] init];
    
    // time_base is the initial timestamp in the dataseries. every piece of accl data is relative to this start time.
    
    NSNumber *time_base = [[NSNumber alloc] init];
    time_base = [data objectForKey:[[NSNumber alloc]initWithInt:[sac[@"KEY_OFFSET"] intValue] + [sac[@"T_TIME_BASE"] intValue]]] ;
    
    
    for (int i=0; i < strap_api_num_samples; i++) {
        NSMutableDictionary *ad = [[NSMutableDictionary alloc] init];
        
        NSNumber *point = [[NSNumber alloc] initWithInteger:[sac[@"KEY_OFFSET"] integerValue]+ (10*i) ];
        
        //ts key
        NSNumber *key = [[NSNumber alloc] initWithInteger: [point integerValue] + [sac[@"T_TS"] integerValue]];
        NSNumber *ts = [data objectForKey:key];
        
        //        NSLog(@"ts: %ld",(long)[ts integerValue]);
        //        NSLog(@"timebase: %ld",(long)[time_base integerValue]);
        NSInteger timestamp = ([ts integerValue] + [time_base integerValue]);
        
        [ad setObject:[[NSNumber alloc] initWithInteger:timestamp]  forKey:@"ts"];
        
        
        //x key
        key = [[NSNumber alloc] initWithInt: ([point intValue] + [sac[@"T_X"] intValue])];
        [ad setObject:[[NSNumber alloc] initWithInt:[[data objectForKey:key] intValue]] forKey:@"x"];
        
        //        NSLog(@"x string: %d",[[data objectForKey:key] intValue]);
        
        //y key
        key = [[NSNumber alloc] initWithInt: ([point intValue] + [sac[@"T_Y"] intValue])];
        [ad setObject:[[NSNumber alloc] initWithInt:[[data objectForKey:key] intValue]] forKey:@"y"];
        
        //        NSLog(@"y string: %d",[[data objectForKey:key] intValue]);
        
        //z key
        key = [[NSNumber alloc] initWithInt: ([point intValue] + [sac[@"T_Z"] intValue])];
        [ad setObject:[[NSNumber alloc] initWithInt:[[data objectForKey:key] intValue]] forKey:@"z"];
        
        //        NSLog(@"z string: %d",[[data objectForKey:key] intValue]);
        
        //did_vibrate key
        key = [[NSNumber alloc] initWithInt: ([point intValue] + [sac[@"T_DID_VIBRATE"] intValue])];
        
        [ad setValue:[NSNumber numberWithBool:[[data objectForKey:key] isEqual: @"1"]] forKey:@"vib"];
        
        //        NSLog(@"did vibrate string: %@",[NSNumber numberWithBool:[[data objectForKey:key] isEqual: @"1"]]);
        
        [ad setValue:[data objectForKey:[[NSNumber alloc] initWithInt:[sac[@"KEY_OFFSET"] intValue] + [sac[@"T_ACTIVITY"] intValue]]] forKey:@"act"];
        
        [convData addObject:ad];
    }
    
    //    NSLog(@"convData: %@",convData);
    
    return convData;
}


+ (void) strap_api_cleanup: (NSTimer *) theTimer logParameters: (NSDictionary *) params
{
    
    //    NSDictionary *empty = [[NSDictionary alloc] init];
    
    //    [self strap_api_log:empty minReadings:0 logParameters:params];
    
    //    NSLog(@"timerFired @ %@", [theTimer fireDate]);
    
}


+ (void) strap_api_log: (NSDictionary*)data minReadings:(int)min_readings logParameters:(NSDictionary*)log_parameters serialNo:(NSString*)serial {
    
    // TODO: get this timer biz working properly so that things that dont reach the minreadings threshold still get pushed up
    
    //    SEL selector = @selector(strap_api_cleanup:logParameters:);
    //
    //    NSMethodSignature *signature = [StrapMetrics instanceMethodSignatureForSelector:selector];
    //
    //    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    //
    //    [invocation setSelector:selector];
    //
    //    [invocation setTarget:self];
    //
    //    [invocation setArgument:(__bridge void *)(log_parameters) atIndex:2];
    //
    //
    //    [strap_api_timer_send invalidate];
    //     strap_api_timer_send = nil;
    //
    //
    //    strap_api_timer_send = [NSTimer scheduledTimerWithTimeInterval:10.0
    //                                    invocation:invocation
    //                                    repeats:NO];
    
    NSDictionary *sac = get_strap_api_const();
    NSDictionary *lp = log_parameters;
    
    long tz_offset = [[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
    NSString *tz = [NSString stringWithFormat:@"%ld",tz_offset];
    
    NSURL *URL = [NSURL URLWithString:strap_api_url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    
    NSMutableString *query = [[NSMutableString alloc]init];
    [query appendString:@"app_id="];
    
    [query appendString:[lp objectForKey:@"app_id"]];
    [query appendString:@"&resolution="];
    [query appendString:[lp objectForKey:@"resolution"]?: @""];
    [query appendString:@"&useragent="];
    [query appendString:[lp objectForKey:@"useragent"]?: @""];
    [query appendString:@"&visitor_id="];
    [query appendString:[lp objectForKey:@"visitor_id"] ?: serial];
    [query appendString:@"&visitor_timeoffset="];
    [query appendString:tz];
    
    
    //    NSLog(@"accl-data-log:%@",[data objectForKey:@([sac[@"KEY_OFFSET"] intValue] + [sac[@"T_ACTIVITY"] intValue])]);
    //    NSLog(@"act-data-log:%@",[data objectForKey:@([sac[@"KEY_OFFSET"] intValue] + [sac[@"T_LOG"] intValue])]);
    
    if( ([data objectForKey:@([sac[@"KEY_OFFSET"] intValue] + [sac[@"T_ACTIVITY"] intValue])] )) {
        // SEND WITH ACCL DATA
        //        NSLog(@"SENDING ACCL EVENT");
        
        NSMutableArray *convData = [self strap_api_convAcclData:data];
        
        [tmpStore addObject:convData];
        
        //        NSLog(@"tmpStore count: %lu",(unsigned long)[tmpStore count]);
        
        
        if ([tmpStore count] > min_readings) {
            
            
            [query appendString:@"&action_url="];
            [query appendString:@"STRAP_API_ACCL"];
            [query appendString:@"&accl="];
            
            NSError *error = NULL;
            
            NSData *jsonData = [[CJSONSerializer serializer] serializeObject:tmpStore error:&error];
            [query appendString:[NSString stringWithUTF8String:[jsonData bytes]]];
            
            
            NSData *data = [query dataUsingEncoding:NSUTF8StringEncoding];
            
            [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request addValue:@"close" forHTTPHeaderField:@"Connection"];
            [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
            
            [request setHTTPBody:data];
            
            NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            
            [tmpStore removeAllObjects];
            
        }
    } else if(([data objectForKey:@([sac[@"KEY_OFFSET"] intValue] + [sac[@"T_LOG"] intValue])] )) {
        // NO ACCL DATA, VANILLA EVENT
        
        //        NSLog(@"SENDING VANILLA EVENT");
        [query appendString:@"&action_url="];
        [query appendString:[data objectForKey:@([sac[@"KEY_OFFSET"] intValue] + [sac[@"T_LOG"] intValue])]?: @"UNKNOWN"];
        
        
        NSData *data = [query dataUsingEncoding:NSUTF8StringEncoding];
        
        [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request addValue:@"close" forHTTPHeaderField:@"Connection"];
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
        request.HTTPBody = data;
        request.timeoutInterval = 30.0;
        
        
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    }
    
    
}



#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [responseData appendData:data];
    //    NSLOG(@"RESPONSE: %@",responseData);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}

@end

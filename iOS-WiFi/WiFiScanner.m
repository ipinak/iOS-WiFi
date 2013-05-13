//
//  WiFiScanner.m
//  iOS-WiFi
//
//  Created by ipinak on 20/03/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "WiFiScanner.h"

#define _IOS_RUN_VERSION_ ([[[UIDevice currentDevice] systemVersion] \
	doubleValue]) /**< Get the version of the iDevice. */

/** 
 * Used only for debugging purposes, you can either set the 
 * same macro on build settings->Preprocessor Macros. 
 */
#define _DEBUG_MODE_

#define _IF_ @"en0"	// Interface name for the wifi

// Access point mode types
#define W_AP_MODE_GATEWAY @"Gateway"
#define W_AP_MODE_BRIDGE @"Bridge"
#define W_AP_MODE_CLIENT @"Client"
#define W_AP_MODE_REPEATER @"Repeater"


@interface WiFiScanner ()
- (void)initVars;
- (void)initdlfcn;
- (NSString *)apMode:(int)type;
@end


@implementation WiFiScanner
@synthesize networks;
@synthesize isScanning, timeInterval;
@synthesize delegate;


/**
 * A regular initialization method for creating an instance of the WiFiScanner.
 * @return The created object from the allocation.
 */
- (id)init
{
	self = [super init];
	if(self) {
		[self initVars];
		[self initdlfcn];
	}
	
	return self;
}

// Initialize all variables.
- (void)initVars
{
	// NSOperation variables.
	executing = NO;
	finished = NO;
	
	// Scanning variables.
	isScanning = NO;
	
	// Allocate space for two dictionaries, these two dictionaries will hold 
	// the information retrieved for all wireless networks scanned.
	networks = [[NSMutableDictionary alloc] init];
	scannedNetworks = [[NSMutableDictionary alloc] init];
}

- (void)initdlfcn
{
	const char *lib_to_load;
	if (_IOS_RUN_VERSION_ >= 4.0 && _IOS_RUN_VERSION_ < 5.0) { ///< iOS 4.x versions.
		lib_to_load = "/System/Library/SystemConfiguration/WiFiManager.bundle/WiFiManager";
	}
	else { ///< iOS 5.x versions.
		lib_to_load = "/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi";
	}
	
	libHandle = dlopen(lib_to_load, RTLD_LAZY);
	
	char *error;
	if (libHandle == NULL && (error = dlerror()) != NULL)  {
#ifdef _DEBUG_MODE_
		NSLog(@"%s", error);
#endif
		exit(1);
	}
	
	// Dynamic loading
	wifiOpen = dlsym(libHandle, "_wifi_manager_open");
	if(wifiOpen == NULL)
		exit(-1);

	wifiBind = dlsym(libHandle, "Apple80211BindToInterface");
	if(wifiBind == NULL)
		exit(-1);

	wifiClose = dlsym(libHandle, "_wifi_manager_close");
	if(wifiClose == NULL)
		exit(-1);

	wifiScan = dlsym(libHandle, "Apple80211Scan");
	if(wifiScan == NULL)
		exit(-1);
}

// Clean up.
- (void)dealloc
{
	dlclose(libHandle);
	wifiClose(airportHandle);

	[networks release];
	[scannedNetworks release];

	[super dealloc];
}

/**
 * Get the mode of the capture in a more user friendly mode.
 * @param type
 * @return 
 */
- (NSString *)apMode:(int)type 
{
	NSString *retVal = nil;
	switch (type) {
		case 1:
			retVal = W_AP_MODE_GATEWAY;
			break;
		case 2:
			retVal = W_AP_MODE_BRIDGE;
			break;
		case 3:
			retVal = W_AP_MODE_CLIENT;
			break;
		case 4:
			retVal = W_AP_MODE_REPEATER;
			break;
	}
	return retVal;
}

#pragma mark -
#pragma mark Scanning methods

/**
 * Scan for networks. This is invoked by the main method of this operation.
 */
- (void)scanNetworks
{
	NSDictionary *parameters = [[NSDictionary alloc] init];
	NSArray *scan_networks = nil;
	
	// Scan for networks.
	int fd_scan = wifiScan(airportHandle, &scan_networks, parameters);
    NSLog(@"fd_scan: %d", fd_scan);
	printf("Scanning...");
	
	for (int i = 0; i < [scan_networks count]; i++) {
		// obj is a generic id type which holds an object of NSDictionary 
		// with information about each network.
		id obj = [scan_networks objectAtIndex:i];	// Temporary object.
		[networks setObject:obj forKey:[obj objectForKey:@"BSSID"]];
	}
	
	// Clean up after each scan.
	[parameters release];
}

// Get the network's information on a dictionary according to its BSSID.
- (NSDictionary *)network:(NSString *)BSSID 
{
	return [networks objectForKey:BSSID];
}

// Return a new dictionary with the specified information only.
- (NSDictionary *)dictionaryDescription 
{
	NSMutableDictionary *dictionaryNetwork = [NSMutableDictionary dictionary];
	NSString *ap_mode = nil;
	
	for (id key in networks) {
		ap_mode = [self apMode:[[[networks objectForKey:key] 
			objectForKey:@"AP_MODE"] intValue]];
		
		// Save wireless information in a new dictionary object
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"AP_MODE"] forKey:@"AP_MODE"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"SSID_STR"] forKey:@"SSID"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"BSSID"] forKey:@"BSSID"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"RSSI"] forKey:@"RSSI"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"CHANNEL"] forKey:@"CHANNEL"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"WEP"] forKey:@"WEP"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"WPA_IE"] forKey:@"WPA"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"NOISE"] forKey:@"NOISE"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"CAPABILITIES"] forKey:@"CAPABILITIES"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"CHANNEL_FLAGS"] forKey:@"CHANNEL_FLAGS"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"AGE"] forKey:@"AGE"];
		[dictionaryNetwork setObject:[[networks objectForKey:key] 
			objectForKey:@"BEACON_INT"] forKey:@"BEACON_INT"];
		
		NSLog(@"--- NETWORK NAME: %@", [[networks objectForKey:key] 
			objectForKey:@"SSID_STR"]);
	}
	return dictionaryNetwork;
}

- (int)numberOfNetworks 
{
	return [networks count];
}


#pragma mark -
#pragma mark NSOperation Overriden method

#define _SCAN_CANCELLED_MSG	@"Scan Cancelled"
#define _UNKNOWN_ERROR_MSG @"Unknown Error"
#define _SCAN_SUCCESS_MSG @"Scan success"

// Main is overidden and calls the method you want to start when the operation 
// starts.
- (void)main 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// If no map is selected then an alert pops to give infomation to the user.
	[self scanNetworks];
	NSCAssert(networks != NULL, @"Networks dictionary is empty...\n");
    
	// Save the results to the database.
	if (![self isCancelled]) {
//		[self printResults];	// Show the results on the cli
		[delegate scanDidFinishWithData:[self networks]
							   andError:_SCAN_SUCCESS_MSG];
	}
	else {
		[delegate scanDidFinishWithData:nil andError:_SCAN_CANCELLED_MSG];
	}
	
	[pool release];
}

- (void)printResults
{
	for (id key in networks) {
		/* age from aDict */
		NSLog(@"%@", [[[networks objectForKey:key] objectForKey:@"AGE"] 
		stringValue]);
		/* access point mode */
		NSLog(@"%@", [[[networks objectForKey:key] objectForKey:@"AP_MODE"] 
		stringValue]);
		/* Beacon int from aDict */
		NSLog(@"%@", [[[networks objectForKey:key] objectForKey:@"BEACON_INT"] 
		stringValue]);
		/* BSSID (MAC Address) */
		NSLog(@"%@", [[networks objectForKey:key] objectForKey:@"BSSID"]);	
		/* Transmission channel */
		NSLog(@"%@", [[[networks objectForKey:key] objectForKey:@"CHANNEL"] 
		stringValue]);
		/* channel flags from aDict */
		NSLog(@"%@", [[[networks objectForKey:key] objectForKey:@"CHANNEL_FLAGS"] 
		stringValue]);
		/* Noise from transmission */
		NSLog(@"%@", [[[networks objectForKey:key] objectForKey:@"NOISE"] 
			stringValue]);
		/* RSSI (Signal Strength) from aDict */
		NSLog(@"%@", [[[networks objectForKey:key] objectForKey:@"RSSI"] 
		stringValue]);
		/* SSID (wifi name) from aDIct */
		NSLog(@"%@", [[networks objectForKey:key] objectForKey:@"SSID_STR"]);
//		/* WEP key*/
//		record.wep = @"";// [[networks objectForKey:key] objectForKey:@"WEP"];
//		/* WPA key */
//		record.wpa = @"";// [[networks objectForKey:key] objectForKey:@"WPA"];
	}
}

@end

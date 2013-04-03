//
//  WiFiScanner.m
//  iOS-WiFi
//
//  Created by ipinak on 20/03/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "WiFiScanner.h"

@implementation WiFiScanner

#define _IOS_RUN_VERSION_ ([[[UIDevice currentDevice] systemVersion] doubleValue]) /**< Get the version of the iDevice. */
/** 
 * Used only for debugging purposes, you can either set the same macro on build settings->Preprocessor Macros. 
 */
#define _DEBUG_MODE_

/**
 * A regular initialization method for creating an instance of the WiFiScanner.
 * @return The created object from the allocation.
 */
- (id)init
{
	self = [super init];
	if(self) {
		const char *lib_to_load;
		if (_IOS_RUN_VERSION_ >= 4.0 && _IOS_RUN_VERSION_ < 5.0) { ///< iOS 4.x versions.
			lib_to_load = "/System/Library/SystemConfiguration/WiFiManager.bundle/WiFiManager";
		}
		else { ///< iOS 5.x versions.
			lib_to_load = "/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi";
		}
		// lib_to_load = "/System/Library/SystemConfiguration/IPConfiguration.bundle/IPConfiguration";
		
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
#ifdef _DEBUG_MODE_
		if(wifiOpen == NULL)
			exit(-1);
#endif
		wifiBind = dlsym(libHandle, "Apple80211BindToInterface");
#ifdef _DEBUG_MODE_
		if(wifiBind == NULL)
			exit(-1);
#endif
		wifiClose = dlsym(libHandle, "_wifi_manager_close");
#ifdef _DEBUG_MODE_	
		if(wifiClose == NULL)
			exit(-1);
#endif
		wifiScan = dlsym(libHandle, "Apple80211Scan");
#ifdef _DEBUG_MODE_	
		if(wifiScan == NULL)
			exit(-1);
#endif
	}
	
	return self;
}

// Clean up.
- (void)dealloc
{
	dlclose(libHandle);
	
	[super dealloc];
}
@end

//
//  WiFiScanner.h
//  iOS-WiFi
//
//  Created by ipinak on 20/03/12.
//  Copyright (c) 2012. All rights reserved.
//

#include <dlfcn.h>

@interface WiFiScanner : NSObject
{	
	void *libHandle;
	void *prefHandle;
	void *airportHandle;
	
	int (* wifiOpen)(void *);
	int (* wifiBind)(void *, NSString *);
	int (* wifiClose)(void *);
	int (* associate)(void *, NSDictionary *, NSString *);
	int (* wifiScan)(void *, NSArray **, void *);
	int (* wifiInfo)(void *, NSDictionary **info);
}
@end

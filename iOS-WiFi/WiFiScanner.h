//
//  WiFiScanner.h
//  iOS-WiFi
//
//  Created by ipinak on 20/03/12.
//  Copyright (c) 2012. All rights reserved.
//

#include <dlfcn.h>

@protocol WiFiScannerDelegate;

/**
 * @brief Scan for available Wireless Lan networks on a separate thread.
 */
@interface WiFiScanner : NSOperation
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

	// Use of delegate to notify the main object.
	id <WiFiScannerDelegate> delegate;

	NSMutableDictionary *networks;
	NSMutableDictionary *scannedNetworks;
	
	BOOL isScanning;

	// NSOperation variables.
	BOOL executing;
	BOOL finished;
}

@property (nonatomic, assign) id <WiFiScannerDelegate> delegate;
@property (nonatomic, retain, readonly) NSMutableDictionary *networks;
@property (nonatomic) BOOL isScanning;
@property (nonatomic) NSTimeInterval timeInterval;

- (NSDictionary *)network:(NSString *)BSSID;
- (void)scanNetworks;
- (NSDictionary *)dictionaryDescription;
- (int)numberOfNetworks;

@end


@protocol WiFiScannerDelegate <NSObject>
// Delegation method, used to notify another object when 
// a specific operation has finished.
@optional
- (void)scanDidFinishWithData:(NSDictionary *)data andError:(NSString *)error;
@end

//
//  DataStoreManager.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

//
//  DataStoreManager.m
//  oxPush2-IOS
//
//  Created by Nazar Yavornytskyy on 2/3/16.
//  Copyright © 2016 Nazar Yavornytskyy. All rights reserved.
//

#import "DataStoreManager.h"
#import <CoreData/CoreData.h>
#import "UserLoginInfo.h"
#import "FDKeychain.h"
#import "KeychainWrapper.h"

#define KEY_ENTITIES @"TokenEntities"
#define USER_INFO_ENTITIES @"LoginInfoEntities"

@implementation DataStoreManager{
	
	NSMutableArray *tokens;
	NSMutableArray *logs;

}

+ (instancetype) sharedInstance {
    static DataStoreManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DataStoreManager alloc] init];
		instance->tokens = [instance getTokenEntities];
		instance->logs = [instance getUserLoginInfo];
    });
    return instance;
}

- (NSArray *)keys {
	return tokens;
}

-(void)saveTokenEntity:(TokenEntity*)tokenEntity {
		
	[tokens removeObject: tokenEntity];
	
    if (tokens != nil){
        [tokens insertObject:tokenEntity atIndex:0];
    } else {
        tokens = [[NSMutableArray alloc] initWithObjects:tokenEntity, nil];
    }
    
	[self saveTokens];
}

- (BOOL)isUniqueTokenName:(NSString *)tokenName {
    
	for (TokenEntity *token in tokens) {
		if ([token.keyName isEqualToString:tokenName] == true) {
			return false;
		} else {
			continue;
		}
	}
    
    return true;
}
    
-(TokenEntity*)getTokenEntityForApplication:(NSString*)app userName:(NSString*)userName {
	    
	for (TokenEntity *token in tokens) {
		if ([token.application isEqualToString:app] && [token.userName isEqualToString: userName]) {
			return token;
		}
	}
	
    return nil;
}
    
// returns unarchived array of tokens or an empty array

-(NSMutableArray *)getTokenEntities{
	
	if (tokens == nil) {
		tokens = [[NSMutableArray alloc] init];
		
		NSArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
		
		if (tokenArray != nil){
			for (NSData* tokenData in tokenArray){
				TokenEntity* token = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
				[tokens addObject:token];
			}
		}
	}
	
	return tokens;
}

- (void)editToken:(TokenEntity *)token name:(NSString *)newName {
	
	if (token != nil) {
		token.keyName = newName;
		[self saveTokens];
	}
}

- (TokenEntity*)getTokenEntity:(TokenEntity *)token {
	
	if (tokens != nil && [tokens containsObject: token]) {
		return [tokens objectAtIndex: [tokens indexOfObject: token]];
	}
	
	return nil;
}

-(TokenEntity*)getTokenEntityByKeyHandle:(NSString*)keyHandle {

	for (TokenEntity *token in tokens) {
		if ([token.keyHandle isEqualToString:keyHandle]) {
			return token;
		}
	}
	
    return nil;
}

-(BOOL)deleteTokenEntity:(TokenEntity *)token {
    
	[tokens removeObject: token];
    
	[self saveTokens];
    
	return NO;
}

-(int)incrementCountForToken:(TokenEntity*)tokenEntity {
    	
	int intCount = [tokenEntity.count intValue];
	intCount += 1;
	tokenEntity.count = [NSString stringWithFormat:@"%d", intCount];
	[self saveTokens];
	return intCount;

}

- (void)saveTokens {
	NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:tokens.count];
	for (TokenEntity *tokenEntity in tokens) {
		if ([tokenEntity isKindOfClass:[NSData class]]){
			[archiveArray addObject:tokenEntity];
		} else {
			NSData *personEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:tokenEntity];
			[archiveArray addObject:personEncodedObject];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:archiveArray forKey:KEY_ENTITIES];
	[[NSUserDefaults standardUserDefaults] synchronize];
	NSLog(@"Saved updated Token Array");
}

- (NSArray *)userLogs {
	return logs;
}

-(void)saveUserLoginInfo:(UserLoginInfo*)userLoginInfo{
    
	[logs addObject: userLoginInfo];
	
	[self saveLogs];
}

-(NSMutableArray*)getUserLoginInfo{
	if (logs == nil) {
		logs = [[NSMutableArray alloc] init];
		NSMutableArray* logsDataArray = [[NSUserDefaults standardUserDefaults] valueForKey:USER_INFO_ENTITIES];
		if (logsDataArray != nil){
			for (NSData* logsData in logsDataArray){
				UserLoginInfo* info = (UserLoginInfo*)[NSKeyedUnarchiver unarchiveObjectWithData:logsData];
				[logs addObject:info];
			}
		}
	}
	
    return logs;
}

-(void)deleteLogs:(NSArray*)logsToDelete{
    
	for (UserLoginInfo* log in logsToDelete){
		[logs removeObject: log];
    }
	
	[self saveLogs];
}

-(void)deleteLog:(UserLoginInfo*) log {

	[logs removeObject: log];
	
	[self saveLogs];
}

-(BOOL)deleteAllLogs {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_INFO_ENTITIES];
	return YES;
}

- (void)saveLogs {
	NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity: logs.count];
	for (UserLoginInfo *userLoginEntity in logs) {
		NSData *personEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:userLoginEntity];
		[archiveArray addObject:personEncodedObject];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:archiveArray forKey:USER_INFO_ENTITIES];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSLog(@"Saved UserLoginInfoEntity to database success");
}

@end

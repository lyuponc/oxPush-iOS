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

}

+ (instancetype) sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(void)saveTokenEntity:(TokenEntity*)tokenEntity {
	
	NSMutableArray* tokenArray = [[self getTokenEntities] mutableCopy];
	TokenEntity * token = [self getTokenEntity:tokenEntity fromArray:tokenArray];
	
	[tokenArray removeObject: token];
	
    if (tokenArray != nil){
        [tokenArray insertObject:tokenEntity atIndex:0];
    } else {
        tokenArray = [[NSMutableArray alloc] initWithObjects:tokenEntity, nil];
    }
    
	[self saveUpdatedTokenArray: tokenArray];
    
}

- (BOOL)isUniqueTokenName:(NSString *)tokenName {
	NSMutableArray* tokenArray = [[self getTokenEntities] mutableCopy];
    
	for (TokenEntity *token in tokenArray) {
		if ([token.keyName isEqualToString:tokenName] == true) {
			return false;
		} else {
			continue;
		}
	}
    
    return true;
}
    
-(TokenEntity*)getTokenEntityForApplication:(NSString*)app userName:(NSString*)userName {
	
    NSMutableArray* tokenArray = [[self getTokenEntities] mutableCopy];
    
	for (TokenEntity *token in tokenArray) {
		if ([token.application isEqualToString:app] && [token.userName isEqualToString: userName]) {
			return token;
		}
	}
	
    return nil;
}
    
// returns unarchived array of tokens or an empty array

-(NSArray *)getTokenEntities{
    NSMutableArray* tokens = [[NSMutableArray alloc] init];
    NSArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
	
    if (tokenArray != nil){
        for (NSData* tokenData in tokenArray){
            TokenEntity* token = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
            [tokens addObject:token];
        }
    }
    return tokens;
}

- (void)editToken:(TokenEntity *)tokenEdited name:(NSString *)newName {
	
	NSMutableArray* tokenArray = [[self getTokenEntities] mutableCopy];
	TokenEntity *token = [self getTokenEntity:tokenEdited fromArray: tokenArray];
	
	if (token != nil) {
		token.keyName = newName;
		[self saveUpdatedTokenArray: tokenArray];
	}
}

- (TokenEntity*)getTokenEntity:(TokenEntity *)token fromArray:(NSArray *)tokenArray {
	if (tokenArray != nil && [tokenArray containsObject: token]) {
		return [tokenArray objectAtIndex: [tokenArray indexOfObject: token]];
	}
	
	return nil;
}

-(TokenEntity*)getTokenEntityByKeyHandle:(NSString*)keyHandle {
	NSMutableArray* tokenArray = [[self getTokenEntities] mutableCopy];

	for (TokenEntity *token in tokenArray) {
		if ([token.keyHandle isEqualToString:keyHandle]) {
			return token;
		}
	}
	
    return nil;
}

- (void)saveUpdatedTokenArray:(NSMutableArray *)tokenArray {
	NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:tokenArray.count];
	for (TokenEntity *tokenEntity in tokenArray) {
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

-(int)incrementCountForToken:(TokenEntity*)tokenEntity {
    
	NSMutableArray* tokenArray = [[self getTokenEntities] mutableCopy];
	TokenEntity *token = [self getTokenEntity:tokenEntity fromArray: tokenArray];
	
	if (token) {
		int intCount = [token.count intValue];
		intCount += 1;
		token.count = [NSString stringWithFormat:@"%d", intCount];
		[self saveUpdatedTokenArray: tokenArray];
	}

    return 0;
}

-(BOOL)deleteTokenEntity:(TokenEntity *)token {
    
	NSMutableArray* tokenArray = [[self getTokenEntities] mutableCopy];
	[tokenArray removeObject: token];
    
	[self saveUpdatedTokenArray: tokenArray];
    
	return NO;
}

-(void)saveUserLoginInfo:(UserLoginInfo*)userLoginInfo{
    
	NSMutableArray* tokenArray = [[self getUserLoginInfo] mutableCopy];
	[tokenArray addObject: userLoginInfo];
	
	[self saveUpdatedUserLoginInfo: tokenArray];
}

-(NSArray*)getUserLoginInfo{
    NSMutableArray* logs = [[NSMutableArray alloc] init];
    NSMutableArray* logsDataArray = [[NSUserDefaults standardUserDefaults] valueForKey:USER_INFO_ENTITIES];
    if (logsDataArray != nil){
        for (NSData* logsData in logsDataArray){
            UserLoginInfo* info = (UserLoginInfo*)[NSKeyedUnarchiver unarchiveObjectWithData:logsData];
            [logs addObject:info];
        }
    }
    return logs;
}

-(void)deleteLogs:(NSArray*)logs{
	NSMutableArray* existingLogs = [[self getUserLoginInfo] mutableCopy];
    
	for (UserLoginInfo* log in logs){
		[existingLogs removeObject: log];
    }
	
	[self saveUpdatedUserLoginInfo: existingLogs];
}

-(void)deleteLog:(UserLoginInfo*) log {
	NSArray* existingLogs = [NSArray arrayWithObjects:log];
	[self deleteLogs: existingLogs];
}

-(BOOL)deleteAllLogs {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_INFO_ENTITIES];
	return YES;
}

- (void)saveUpdatedUserLoginInfo:(NSMutableArray *) logs {
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

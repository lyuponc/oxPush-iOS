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
	
	[self deleteTokenEntityForApplication: tokenEntity.application userName: tokenEntity.userName];
	
	NSMutableArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
    if (tokenArray != nil){
        [tokenArray insertObject:tokenEntity atIndex:0];
    } else {
        tokenArray = [[NSMutableArray alloc] initWithObjects:tokenEntity, nil];
    }
    
	[self saveUpdatedTokenArray: tokenArray];
    
}

- (BOOL)isUniqueTokenName:(NSString *)tokenName {
    NSMutableArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
    
    if (tokenArray != nil){
        for (NSData* tokenData in tokenArray) {
            TokenEntity* token = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
            if ([token.keyName isEqualToString:tokenName] == true) {
                return false;
            } else {
                continue;
            }
        }
    }
    
    return true;
}
    
-(TokenEntity*)getTokenEntityForApplication:(NSString*)app userName:(NSString*)userName {
    NSMutableArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
    if (tokenArray != nil){
        for (NSData* tokenData in tokenArray){
            TokenEntity* token = (TokenEntity*)[NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
            if ([token isKindOfClass:[TokenEntity class]] && [token.application isEqualToString:app] && [token.userName isEqualToString:userName]) {
                return token;
            }
        }
    }
	
	return nil;
}
    
-(NSArray*)getTokenEntities{
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

- (void)editTokenName:(TokenEntity *)tokenEdited name:(NSString *) newName {
	
    NSMutableArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
	
	TokenEntity* existingToken = [self getTokenEntityForApplication: tokenEdited.application userName: tokenEdited.userName];
	
	if (existingToken != nil) {
		existingToken.keyName = newName;
		[self saveUpdatedTokenArray: newTokenArray];
	}
}

-(TokenEntity*)getTokenEntityByKeyHandle:(NSString*)keyHandle{
    NSMutableArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
    if (tokenArray != nil){
        for (NSData* tokenData in tokenArray){
            TokenEntity* token = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
            if ([token.keyHandle isEqualToString:keyHandle]) {
                return token;
            }
        }
    }

    return nil;
}

- (void)saveUpdatedTokenArray:(NSMutableArray *)tokenArray {
	NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:tokenArray.count];
	for (TokenEntity *tokenEntity in newTokenArray) {
		if ([tokenEntity isKindOfClass:[NSData class]]){
			[archiveArray addObject:tokenEntity];
		} else {
			NSData *personEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:tokenEntity];
			[archiveArray addObject:personEncodedObject];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:archiveArray forKey:KEY_ENTITIES];
	NSLog(@"Saved new TokenEntity name in database success");
}

-(int)incrementCountForToken:(TokenEntity*)tokenEntity{
    
    NSMutableArray* tokenArray = (NSMutableArray*)[[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
	TokenEntity* existingToken = [self getTokenEntityForApplication: tokenEntity.application userName: tokenEntity.userName];
	
	if (existingToken != nil) {
		int intCount = [existingToken.count intVaue];
		intCount.count += 1;
		existingToken.count = [NSString stringWithFormat:@"%d", intCount];
		[self saveUpdatedTokenArray: tokenArray];
		
		return intCount;
	}
	
    return 0;
}

-(BOOL)deleteTokenEntityForApplication:(NSString*)app userName:(NSString*) userName {
    NSMutableArray* tokenArray = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_ENTITIES];
    NSMutableArray* newTokenArray = [[NSMutableArray alloc] initWithArray:tokenArray];
    if (tokenArray != nil){
        for (NSData* tokenData in tokenArray){
            TokenEntity* token = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
            if ([token.application isEqualToString:app] && [token.userName isEqualToString:userName]) {
                [newTokenArray removeObject:tokenData];
            }
        }
    }
    
	[self saveUpdatedTokenArray: newTokenArray];
    return NO;
}

-(void)saveUserLoginInfo:(UserLoginInfo*)userLoginInfo{
    
    NSMutableArray* logs = [[NSUserDefaults standardUserDefaults] valueForKey:USER_INFO_ENTITIES];
    NSMutableArray* newlogs = [[NSMutableArray alloc] init];
    if (logs == nil){
        [newlogs addObject:userLoginInfo];
    } else {
        [newlogs addObject:userLoginInfo];
        for (NSData* logsData in logs){
            UserLoginInfo* info = (UserLoginInfo*)[NSKeyedUnarchiver unarchiveObjectWithData:logsData];
            [newlogs addObject:info];
        }
    }
    
	[self saveUpdatedUserLoginInfo: newlogs];
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
    for (UserLoginInfo* info in logs){
        [[DataStoreManager sharedInstance] deleteLog:info];
    }
}

-(void)deleteLog:(UserLoginInfo*) log {
    NSMutableArray* logs = [[NSUserDefaults standardUserDefaults] valueForKey:USER_INFO_ENTITIES];
    NSMutableArray* newlogs = [[NSMutableArray alloc] init];
    for (NSData* logsData in logs){
        UserLoginInfo* info = (UserLoginInfo*)[NSKeyedUnarchiver unarchiveObjectWithData:logsData];
        if (![info.created isEqualToString:log.created]){
            [newlogs addObject:info];
        }
    }

	[self saveUpdatedUserLoginInfo: newlogs];
}

-(BOOL)deleteAllLogs{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_INFO_ENTITIES];
	return YES;
}

- (void)saveUpdatedUserLoginInfo:(NSMutableArray *) logs {
	NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:newlogs.count];
	for (UserLoginInfo *userLoginEntity in newlogs) {
		NSData *personEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:userLoginEntity];
		[archiveArray addObject:personEncodedObject];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:archiveArray forKey:USER_INFO_ENTITIES];
	
	NSLog(@"Saved UserLoginInfoEntity to database success");
}

@end

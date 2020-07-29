//
//  RSA.h
//  Konverter
//
//  Created by YouShaoduo on 2020/7/29.
//  Copyright © 2020 Youssef. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RSA : NSObject
#pragma mark - 使用'.der'公钥文件加密
+ (NSString *)encryptString:(NSString *)str publicKeyWithContentsOfFile:(NSString *)path;

#pragma mark - 使用'.der'公钥文件解密
+ (NSString *)decryptString:(NSString *)str publicKeyWithContentsOfFile:(NSString *)path;

#pragma mark - 使用'.12'私钥文件解密
+ (NSString *)decryptString:(NSString *)str privateKeyWithContentsOfFile:(NSString *)path password:(NSString *)password;

#pragma mark - 使用'.12'私钥文件加密
+ (NSString *)encryptString:(NSString *)str privateKeyWithContentsOfFile:(NSString *)path password:(NSString *)password;

#pragma mark - 使用公钥字符串解密
+ (NSString *)decryptString:(NSString *)str publicKey:(NSString *)pubKey;

#pragma mark - 使用公钥字符串加密
+ (NSString *)encryptString:(NSString *)str publicKey:(NSString *)pubKey;

#pragma mark - 使用私钥字符串解密
+ (NSString *)decryptString:(NSString *)str privateKey:(NSString *)privKey;

#pragma mark - 使用私钥字符串加密
+ (NSString *)encryptString:(NSString *)str privateKey:(NSString *)privKey;
@end

NS_ASSUME_NONNULL_END

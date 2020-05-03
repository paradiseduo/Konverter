#import "Utils.h"

NSString* decode64(NSString* str){
    
    str = [str stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    str = [str stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    if(str.length%4){
        NSInteger length = (4-str.length%4) + str.length;
        str = [str stringByPaddingToLength: length withString:@"=" startingAtIndex:0];
    }
    NSData* decodeData = [[NSData alloc] initWithBase64EncodedString:str options:0];
    NSString* decodeStr = [[NSString alloc] initWithData:decodeData encoding:NSUTF8StringEncoding];
    if (decodeStr == nil) {
        decodeStr = @"";
    }
    return decodeStr;
}

NSString* encode64(NSString* str){
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSString *stringBase64 = [data base64EncodedStringWithOptions: NSDataBase64EncodingEndLineWithCarriageReturn];
    stringBase64 = [stringBase64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    stringBase64 = [stringBase64 stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    stringBase64 = [stringBase64 stringByReplacingOccurrencesOfString:@"=" withString:@""];
    return stringBase64;
}

NSString* ParseDecodeString(NSURL* url){
    if(!url.host){
        return @"";
    }
    NSString *urlString = [url absoluteString];
    if ([urlString hasPrefix:@"ss://"]) {
        return ParseSSURLDecodeString(url);
    }
    if ([urlString hasPrefix:@"ssr://"]) {
        return ParseSSRURLDecodeString(url);
    }
    return @"";
}

// 解析SS URL，如果成功则返回一个与ServerProfile类兼容的dict
// 或SSR URL，ServerProfile类已经默认添加SSR参数，默认放空，如果URL为SSR://则改变解析方法
// ss:// + base64(method:password@domain:port)
static NSString* ParseSSURLDecodeString(NSURL* url) {
    if (!url.host) {
        return nil;
    }
    
    NSString *urlString = [url absoluteString];
    int i = 0;
    NSString *errorReason = nil;
    if([urlString hasPrefix:@"ss://"]){
        while(i < 2) {
            if (i == 1) {
                NSString* host = url.host;
                if ([host length]%4!=0) {
                    int n = 4 - [host length]%4;
                    if (1==n) {
                        host = [host stringByAppendingString:@"="];
                    } else if (2==n) {
                        host = [host stringByAppendingString:@"=="];
                    }
                }
                NSData *data = [[NSData alloc] initWithBase64EncodedString:host options:0];
                NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                urlString = decodedString;
            }
            i++;
            urlString = [urlString stringByReplacingOccurrencesOfString:@"ss://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
            NSRange firstColonRange = [urlString rangeOfString:@":"];
            NSRange lastColonRange = [urlString rangeOfString:@":" options:NSBackwardsSearch];
            NSRange lastAtRange = [urlString rangeOfString:@"@" options:NSBackwardsSearch];
            if (firstColonRange.length == 0) {
                errorReason = @"colon not found";
                continue;
            }
            if (firstColonRange.location == lastColonRange.location) {
                errorReason = @"only one colon";
                continue;
            }
            if (lastAtRange.length == 0) {
                errorReason = @"at not found";
                continue;
            }
            if (!((firstColonRange.location < lastAtRange.location) && (lastAtRange.location < lastColonRange.location))) {
                errorReason = @"wrong position";
                continue;
            }
            NSString *method = [urlString substringWithRange:NSMakeRange(0, firstColonRange.location)];
            NSString *password = [urlString substringWithRange:NSMakeRange(firstColonRange.location + 1, lastAtRange.location - firstColonRange.location - 1)];
            NSString *IP = [urlString substringWithRange:NSMakeRange(lastAtRange.location + 1, lastColonRange.location - lastAtRange.location - 1)];
            NSString *port = [urlString substringWithRange:NSMakeRange(lastColonRange.location + 1, urlString.length - lastColonRange.location - 1)];
            
            return [NSString stringWithFormat:@"sr://%@:%@@%@:%@", method,password,IP,port];
        }

    }
    return @"";
}

static NSString* ParseSSRURLDecodeString(NSURL* url) {
    NSString *urlString = [url absoluteString];
    NSString *firstParam;
    NSString *lastParam;
    //if ([urlString hasPrefix:@"ssr://"]){
    // ssr:// + base64(abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}/?obfsparam={base64(混淆参数(网址))}&protoparam={base64(混淆协议)}&remarks={base64(节点名称)}&group={base64(分组名)})
    
    urlString = [urlString stringByReplacingOccurrencesOfString:@"ssr://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
    NSString *decodedString = decode64(urlString);
    if ([decodedString isEqual: @""]) {
        return @"";
    }else{
        NSRange paramSplit = [decodedString rangeOfString:@"?"];
        
        if (paramSplit.length == 0){
            firstParam = decodedString;
        } else {
            firstParam = [decodedString substringToIndex:paramSplit.location-1];
            lastParam = [decodedString substringFromIndex:paramSplit.location];
        }
   
        NSDictionary *parserLastParamDict = parseSSRLastParam(lastParam, false);
        
        //后面已经parser完成，接下来需要解析到profile里面
        //abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}
        NSRange range = [firstParam rangeOfString:@":"];
        NSString *ip = [firstParam substringToIndex:range.location];//第一个参数是域名
        
        firstParam = [firstParam substringFromIndex:range.location + range.length];
        range = [firstParam rangeOfString:@":"];
        NSString *port = [firstParam substringToIndex:range.location];//第二个参数是端口
        
        firstParam = [firstParam substringFromIndex:range.location + range.length];
        range = [firstParam rangeOfString:@":"];
        NSString *ssrProtocol = [firstParam substringToIndex:range.location];//第三个参数是协议
        
        firstParam = [firstParam substringFromIndex:range.location + range.length];
        range = [firstParam rangeOfString:@":"];
        NSString *encryption = [firstParam substringToIndex:range.location];//第四个参数是加密
        
        firstParam = [firstParam substringFromIndex:range.location + range.length];
        range = [firstParam rangeOfString:@":"];
        NSString *ssrObfs = [firstParam substringToIndex:range.location];//第五个参数是混淆协议
        
        firstParam = [firstParam substringFromIndex:range.location + range.length];
        NSString *password = decode64(firstParam);
        
        NSString *ssrObfsParam = @"";
        NSString *remarks = @"";
        NSString *ssrProtocolParam = @"";
        NSString *ssrGroup = @"";
        for (NSString *key in parserLastParamDict) {
            if ([key  isEqual: @"obfsparam"]) {
                ssrObfsParam = parserLastParamDict[key];
            } else if ([key  isEqual: @"remarks"]) {
                remarks = parserLastParamDict[key];
            } else if([key isEqual:@"protoparam"]){
                ssrProtocolParam = parserLastParamDict[key];
            } else if([key isEqual:@"group"]){
                ssrGroup = parserLastParamDict[key];
            }
        }
        return [NSString stringWithFormat:@"ssr://%@:%@:%@:%@:%@:%@/?obfsparam=%@&protoparam=%@&remarks=%@&group=%@", ip, port, ssrProtocol, encryption, ssrObfs, password, ssrObfsParam, ssrProtocolParam, remarks, ssrGroup];
    }
}

NSString* ParseEncodeString(NSString* url){
    if ([url hasPrefix:@"ss://"]) {
        return ParseSSURLEncodeString(url);
    }
    if ([url hasPrefix:@"ssr://"]) {
        return ParseSSRURLEncodeString(url);
    }
    return url;
}

static NSString* ParseSSURLEncodeString(NSString* url) {
    NSString *urlString = url;
    int i = 0;
    NSString *errorReason = nil;
    if([urlString hasPrefix:@"ss://"]){
        while(i < 2) {
            if (i == 1) {
                NSString* host = [urlString stringByReplacingOccurrencesOfString:@"ss://" withString:@""];
                if ([host length]%4!=0) {
                    int n = 4 - [host length]%4;
                    if (1==n) {
                        host = [host stringByAppendingString:@"="];
                    } else if (2==n) {
                        host = [host stringByAppendingString:@"=="];
                    }
                }
                NSData *data = [[NSData alloc] initWithBase64EncodedString:host options:0];
                NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                urlString = decodedString;
            }
            i++;
            urlString = [urlString stringByReplacingOccurrencesOfString:@"ss://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
            NSRange firstColonRange = [urlString rangeOfString:@":"];
            NSRange lastColonRange = [urlString rangeOfString:@":" options:NSBackwardsSearch];
            NSRange lastAtRange = [urlString rangeOfString:@"@" options:NSBackwardsSearch];
            if (firstColonRange.length == 0) {
                errorReason = @"colon not found";
                continue;
            }
            if (firstColonRange.location == lastColonRange.location) {
                errorReason = @"only one colon";
                continue;
            }
            if (lastAtRange.length == 0) {
                errorReason = @"at not found";
                continue;
            }
            if (!((firstColonRange.location < lastAtRange.location) && (lastAtRange.location < lastColonRange.location))) {
                errorReason = @"wrong position";
                continue;
            }
            NSString *method = [urlString substringWithRange:NSMakeRange(0, firstColonRange.location)];
            NSString *password = [urlString substringWithRange:NSMakeRange(firstColonRange.location + 1, lastAtRange.location - firstColonRange.location - 1)];
            NSString *IP = [urlString substringWithRange:NSMakeRange(lastAtRange.location + 1, lastColonRange.location - lastAtRange.location - 1)];
            NSString *port = [urlString substringWithRange:NSMakeRange(lastColonRange.location + 1, urlString.length - lastColonRange.location - 1)];
            
            return [NSString stringWithFormat:@"ss://%@:%@@%@:%@", method,password,IP,port];
        }

    }
    return @"";
}

static NSString* ParseSSRURLEncodeString(NSString* url) {
    NSString *urlString = url;
    NSString *firstParam;
    NSString *lastParam;
    
    urlString = [urlString stringByReplacingOccurrencesOfString:@"ssr://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
    NSRange paramSplit = [urlString rangeOfString:@"?"];
    
    if (paramSplit.length == 0){
        firstParam = urlString;
    } else {
        firstParam = [urlString substringToIndex:paramSplit.location-1];
        lastParam = [urlString substringFromIndex:paramSplit.location];
    }

    NSDictionary *parserLastParamDict = parseSSRLastParam(lastParam, true);
    
    //后面已经parser完成，接下来需要解析到profile里面
    //abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}
    NSRange range = [firstParam rangeOfString:@":"];
    NSString *ip = [firstParam substringToIndex:range.location];//第一个参数是域名
    
    firstParam = [firstParam substringFromIndex:range.location + range.length];
    range = [firstParam rangeOfString:@":"];
    NSString *port = [firstParam substringToIndex:range.location];//第二个参数是端口
    
    firstParam = [firstParam substringFromIndex:range.location + range.length];
    range = [firstParam rangeOfString:@":"];
    NSString *ssrProtocol = [firstParam substringToIndex:range.location];//第三个参数是协议
    
    firstParam = [firstParam substringFromIndex:range.location + range.length];
    range = [firstParam rangeOfString:@":"];
    NSString *encryption = [firstParam substringToIndex:range.location];//第四个参数是加密
    
    firstParam = [firstParam substringFromIndex:range.location + range.length];
    range = [firstParam rangeOfString:@":"];
    NSString *ssrObfs = [firstParam substringToIndex:range.location];//第五个参数是混淆协议
    
    firstParam = [firstParam substringFromIndex:range.location + range.length];
    NSString *password = encode64(firstParam);
    
    NSString *ssrObfsParam = @"";
    NSString *remarks = @"";
    NSString *ssrProtocolParam = @"";
    NSString *ssrGroup = @"";
    for (NSString *key in parserLastParamDict) {
        if ([key  isEqual: @"obfsparam"]) {
            ssrObfsParam = parserLastParamDict[key];
        } else if ([key  isEqual: @"remarks"]) {
            remarks = parserLastParamDict[key];
        } else if([key isEqual:@"protoparam"]){
            ssrProtocolParam = parserLastParamDict[key];
        } else if([key isEqual:@"group"]){
            ssrGroup = parserLastParamDict[key];
        }
    }
    // ssr://base64(abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}/?obfsparam={base64(混淆参数(网址))}&protoparam={base64(混淆协议)}&remarks={base64(节点名称)}&group={base64(分组名)})
    NSString * s = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@/?obfsparam=%@&protoparam=%@&remarks=%@&group=%@", ip, port, ssrProtocol, encryption, ssrObfs, password, ssrObfsParam, ssrProtocolParam, remarks, ssrGroup];
    return [NSString stringWithFormat:@"ssr://%@", encode64(s)];
}

static NSDictionary<NSString*, id>* parseSSRLastParam(NSString* lastParam, BOOL encoding){
    NSMutableDictionary *parserLastParamDict = [[NSMutableDictionary alloc]init];
    if(lastParam.length == 0){
        return nil;
    }
    lastParam = [lastParam substringFromIndex:1];
    NSArray *lastParamArray = [lastParam componentsSeparatedByString:@"&"];
    for (int i=0; i<lastParamArray.count; i++) {
        NSString *toSplitString = lastParamArray[i];
        NSRange lastParamSplit = [toSplitString rangeOfString:@"="];
        if (lastParamSplit.location != NSNotFound) {
            NSString *key = [toSplitString substringToIndex:lastParamSplit.location];
            NSString *value = @"";
            if (encoding) {
                value = encode64([toSplitString substringFromIndex:lastParamSplit.location+1]);
            } else {
                value = decode64([toSplitString substringFromIndex:lastParamSplit.location+1]);
            }
            [parserLastParamDict setValue: value forKey: key];
        }
    }
    return parserLastParamDict;
}

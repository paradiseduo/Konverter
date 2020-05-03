#import <Foundation/Foundation.h>
#ifndef QRCodeUtils_h
#define QRCodeUtils_h

NSString* decode64(NSString* str);

NSString* encode64(NSString* str);

NSString* ParseDecodeString(NSURL* url);

NSString* ParseEncodeString(NSString* url);

static NSString* ParseSSURLDecodeString(NSURL* url);

static NSString* ParseSSRURLDecodeString(NSURL* url);

static NSString* ParseSSURLEncodeString(NSString* url);

static NSString* ParseSSRURLEncodeString(NSString* url);

static NSDictionary<NSString*, id>* parseSSRLastParam(NSString* lastParam, BOOL encoding);

#endif /* QRCodeUtils_h */

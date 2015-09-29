#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "ItemLocalizable.h"

@interface EditorLocalizable : NSObject

+(NSString *) defaultPathLocalizablePath;

+(void) saveItemLocalizable:(ItemLocalizable *)itemLocalizable
                     toPath:(NSString *) toPath;

+(NSString *) chooseFileLocalizableString;

//+(NSArray *) sessionArrayOfPath:(NSString *)path;
+(NSDictionary *)allSessionAndKeysAtPath:(NSString *)path;

+(NSString *) lastSession;
+(NSString *) lastKey;

+(NSString *) valueForLocalizationKey:(NSString *)key atPath:(NSString *)path;

+ (void)deleteKey:(NSString *)key atPath:(NSString *)path andComplete:(void(^)(BOOL))completeBlock;
@end

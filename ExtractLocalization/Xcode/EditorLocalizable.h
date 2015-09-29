#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "ItemLocalizable.h"

@interface EditorLocalizable : NSObject

+(NSString *) defaultPathLocalizablePath;

+(void) saveItemLocalizable:(ItemLocalizable *)itemLocalizable
                     toPath:(NSString *) toPath;

+(NSString *) chooseFileLocalizableString;

+(NSArray *) sessionArrayOfPath:(NSString *)path;

@end

#import <Foundation/Foundation.h>

@interface ItemLocalizable : NSObject

@property (strong) NSString * session;
@property (strong) NSString * key;
@property (strong) NSString * value;

-(id)initWithKey:(NSString *) key
        andValue:(NSString *) value;

-(id)initWithKey:(NSString *) key
        andValue:(NSString *) value
      andSession:(NSString *) session;

@end

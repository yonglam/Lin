#import "ItemLocalizable.h"

@implementation ItemLocalizable

-(id)initWithKey:(NSString *) key
        andValue:(NSString *) value
      andSession:(NSString *)session{
    self = [super init];
    if (self) {
        self.value = value;
        self.key = key;
        self.session = session;
    }
    return self;
}

-(id)initWithKey:(NSString *) key
        andValue:(NSString *) value
{
    return [self initWithKey:key andValue:value andSession:nil];
}
@end

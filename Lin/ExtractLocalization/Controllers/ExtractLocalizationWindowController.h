#import <Cocoa/Cocoa.h>
#import "ItemLocalizable.h"

typedef enum : NSUInteger {
    ELWindowTypeNew,
    ELWindowTypeEdit,
} ELWindowType;

@interface ExtractLocalizationWindowController : NSWindowController

@property (weak) IBOutlet NSComboBox * boxKey;
@property (weak) IBOutlet NSTextField * txtValue;
@property (weak) IBOutlet NSComboBox  * boxSession;
@property (copy) void (^extractLocalizationDidConfirm)(ItemLocalizable * item);

- (instancetype)initWithItem:(ItemLocalizable *)item type:(ELWindowType)type;

-(IBAction)doClickOK:(id)sender;
-(IBAction)doReturn:(id)sender;

-(void)showWindow;

//-(void)fillFieldKey:(NSString *) key;
//-(void)fillFieldValue:(NSString *) value;

@end

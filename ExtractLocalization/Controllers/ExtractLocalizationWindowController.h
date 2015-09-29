#import <Cocoa/Cocoa.h>
#import "ItemLocalizable.h"

@interface ExtractLocalizationWindowController : NSWindowController

@property (weak) IBOutlet NSTextField * txtKey;
@property (weak) IBOutlet NSTextField * txtValue;
@property (weak) IBOutlet NSComboBox  * boxSession;
@property (copy) void (^extractLocalizationDidConfirm)(ItemLocalizable * item);

-(IBAction)doClickOK:(id)sender;
-(IBAction)doReturn:(id)sender;

-(void)showWindow;

-(void)fillFieldValue:(NSString *) value;

@end

#import "ExtractLocalizationWindowController.h"
#import "EditorLocalizable.h"

@interface ExtractLocalizationWindowController () <NSComboBoxDataSource>

@end

@implementation ExtractLocalizationWindowController{
    NSArray *_sessions;
}

- (void)windowDidLoad
{
    _boxSession.dataSource = self;
    _sessions = [EditorLocalizable sessionArrayOfPath:[EditorLocalizable defaultPathLocalizablePath]];
}

-(IBAction)doClickOK:(id)sender{
    if (_txtKey.stringValue.length <= 0 || _txtValue.stringValue.length <= 0) {
        return;
    }
    
    ItemLocalizable * item = [[ItemLocalizable alloc]
                              initWithKey:_txtKey.stringValue
                              andValue:_txtValue.stringValue
                              andSession:_boxSession.stringValue];
    _extractLocalizationDidConfirm(item);
    [[self window ]orderOut:self];
}


-(IBAction)doReturn:(id)sender
{
    [self doClickOK:sender];
}

-(void)showWindow{
    [self.window center];
    [self showWindow:nil];
}

-(void)fillFieldValue:(NSString *) value{
//    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
//    value = [value stringByReplacingOccurrencesOfString:@"@" withString:@""];
    _txtValue.stringValue = value;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [_sessions count];
}
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return [_sessions objectAtIndex:index];
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string
{
    __block NSUInteger index = NSNotFound;
    [_sessions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([(NSString *)obj hasPrefix:string]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}
- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)string
{
    __block NSString *rst = nil;
    [_sessions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([(NSString *)obj hasPrefix:string]) {
            rst = obj;
            *stop = YES;
        }
    }];
    return rst;
}
@end

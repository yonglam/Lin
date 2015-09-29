#import "ExtractLocalizationWindowController.h"
#import "EditorLocalizable.h"

@interface ExtractLocalizationWindowController () <NSComboBoxDataSource,NSComboBoxDelegate>

@end

@implementation ExtractLocalizationWindowController{
    NSArray *_sessions;
    NSDictionary *_session2KeysDict;
    ItemLocalizable *_item;
    ELWindowType _type;
}

- (instancetype)initWithItem:(ItemLocalizable *)item type:(ELWindowType)type
{
    self = [super initWithWindowNibName:@"ExtractLocalizationWindowController"];
    if (self) {
        _item = item;
        _type = type;
    }
    return self;
}

- (void)windowDidLoad
{
    if (ELWindowTypeNew == _type) {
        [self.window setTitle:@"Add an Item"];
    }
    else {
        [self.window setTitle:@"Edit an Item"];
    }
    
    _boxSession.dataSource = self;
    
    _session2KeysDict = [EditorLocalizable allSessionAndKeysAtPath:[EditorLocalizable defaultPathLocalizablePath]];
    _sessions = [_session2KeysDict.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 compare:obj1 options:NSCaseInsensitiveSearch];
    }];
    
    
    if (_type == ELWindowTypeEdit) {
        _boxSession.enabled = NO;
        _boxKey.enabled = NO;
    }
    
    if (_item.session.length > 0) {
        _boxSession.stringValue = _item.session;
    }
    else if(_type == ELWindowTypeNew){
        NSString *lastSession = [EditorLocalizable lastSession];
        if (lastSession.length > 0) {
            _boxSession.stringValue = lastSession;
        }
    }
    
    if (_item.key.length > 0) {
        _boxKey.stringValue = _item.key;
    }
    else if(_type == ELWindowTypeNew){
        NSString *lastKey = [EditorLocalizable lastKey];
        if (lastKey.length > 0) {
            _boxKey.placeholderString = lastKey;
        }
    }
    
    if (_item.value.length > 0) {
        _txtValue.stringValue = _item.value;
    }
}

-(IBAction)doClickOK:(id)sender{
    if (_boxKey.stringValue.length <= 0 ||
        _txtValue.stringValue.length <= 0 ||
        (_boxSession.stringValue.length <= 0 && _type == ELWindowTypeNew)) {
        return;
    }
    
    ItemLocalizable * item = [[ItemLocalizable alloc]
                              initWithKey:_boxKey.stringValue
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

//-(void)fillFieldValue:(NSString *) value{
//    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
//    value = [value stringByReplacingOccurrencesOfString:@"@" withString:@""];
//    _txtValue.stringValue = value;
//}

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
        if ([(NSString *)obj rangeOfString:string options:NSCaseInsensitiveSearch].location == 0) {
            rst = obj;
            *stop = YES;
        }
    }];
    return rst;
}

- (void)comboBoxWillPopUp:(NSNotification *)notification
{
    [_boxKey removeAllItems];
    NSArray *keys = _session2KeysDict[_boxSession.stringValue];
    [_boxKey addItemsWithObjectValues:keys];
}
@end

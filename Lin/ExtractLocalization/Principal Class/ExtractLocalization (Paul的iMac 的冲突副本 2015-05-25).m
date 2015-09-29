#import "ExtractLocalization.h"
#import "RCXcode.h"
#import "ExtractLocalizationWindowController.h"
#import "EditorLocalizable.h"
#import "Logger.h"

static NSString *localizeRegex = @"NSLocalizedString\\s*\\(\\s*@\"(.*)\"\\s*,\\s*(.*)\\s*\\)|LOCALSTR\\s*\\(\\s*@\"(.*)\"\\s*\\)";
static NSString *stringRegexsObjectiveC = @"@\"([^\"]*)\"";
//static NSString *stringRegexsObjectiveC = @"@\"(.*)\"";
static NSString *stringRegexsSwift = @"\"([^\"]*)\"";
static NSString * defaultStringRegex;
static NSString * defaultStringLocalizeRegex;
static NSString * defaultStringLocalizeFormat;
static BOOL  isSwift;

@implementation ExtractLocalization

static id sharedPlugin = nil;

/*
+(void)pluginDidLoad:(NSBundle *)plugin {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc]initWithBundle:plugin];
    });
}

-(id)initWithBundle:(NSBundle *)bundle{
    if (self = [super init]) {
        [self createMenuExtractLocalization];
    }
    return self;
}
 */

+(instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc]init];
    });
    return sharedPlugin;
}

+(BOOL)isSwift{
    return isSwift;
}

- (void)createMenuExtractLocalization {
    NSMenuItem *editMenu = [[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"Edit", @"Edit")];
    if (editMenu) {
        NSMenuItem *refactorMenu = [[editMenu submenu] itemWithTitle:NSLocalizedString(@"Refactor", @"Refactor")];
    
        NSMenuItem *extractLocalizationStringMenu = [[NSMenuItem alloc] initWithTitle:@"Extract Localizable String" action:@selector(extractLocalization) keyEquivalent:@"u"];
        [extractLocalizationStringMenu setKeyEquivalentModifierMask:NSShiftKeyMask | NSAlternateKeyMask];
        [extractLocalizationStringMenu setTarget:self];
        
        NSMenuItem *deleteLocalizationMenu = [[NSMenuItem alloc] initWithTitle:@"Delete Localization Define" action:@selector(deleteLocalizationDefine) keyEquivalent:@"d"];
        [deleteLocalizationMenu setKeyEquivalentModifierMask:NSShiftKeyMask | NSAlternateKeyMask];
        [deleteLocalizationMenu setTarget:self];

        [[refactorMenu submenu]addItem:extractLocalizationStringMenu];
        [[refactorMenu submenu]addItem:deleteLocalizationMenu];
    }
    
}

- (void)setupParamsForFileExt:(NSString *)fileExtesion
{
        if ([fileExtesion isEqualToString:@"swift"]) {
        isSwift = YES;
        defaultStringRegex = stringRegexsSwift;
        defaultStringLocalizeRegex =  @"NSLocalizedString\\s*\\(\\s*\"(.*)\"\\s*,\\s*(.*)\\s*\\)";
        defaultStringLocalizeFormat=  @"NSLocalizedString(\"%@\",comment:\"\")";
    }else{
        isSwift = NO;
        defaultStringRegex = stringRegexsObjectiveC;
        defaultStringLocalizeRegex = localizeRegex;
        //        defaultStringLocalizeFormat= @"NSLocalizedString(@\"%@\",nil)";
        defaultStringLocalizeFormat= @"LOCALSTR(@\"%@\")";
    }
    self.defaultLocalizableFilePath = [EditorLocalizable defaultPathLocalizablePath];
}

- (void)deleteLocalizationDefine
{
    RCIDESourceCodeDocument *document = [RCXcode currentSourceCodeDocument];
    NSTextView *textView = [RCXcode currentSourceCodeTextView];
    if (!document || !textView) {
        return;
    }
    
    NSString * fileExtesion = [[document.displayName componentsSeparatedByString:@"."] objectAtIndex:1];
    [self setupParamsForFileExt:fileExtesion];

    
    NSArray *selectedRanges = [textView selectedRanges];
    if ([selectedRanges count] > 0) {
        NSRange range = [[selectedRanges objectAtIndex:0] rangeValue];
        NSRange lineRange = [textView.textStorage.string lineRangeForRange:range];
        NSString *line = [textView.textStorage.string substringWithRange:lineRange];
        NSRegularExpression *localizedRex = [[NSRegularExpression alloc] initWithPattern:defaultStringLocalizeRegex options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *localizedMatches = [localizedRex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
        if ([localizedMatches count] > 0) {
            NSTextCheckingResult *localizedMatch = [localizedMatches firstObject];
            NSString *localizedString = [line substringWithRange:localizedMatch.range];
            NSRegularExpression *stringRex = [[NSRegularExpression alloc] initWithPattern:defaultStringRegex options:NSRegularExpressionCaseInsensitive error:nil];
            NSTextCheckingResult *stringResult = [stringRex firstMatchInString:localizedString options:0 range:NSMakeRange(0, localizedString.length)];
            NSString *keyStr = [localizedString substringWithRange:[stringResult rangeAtIndex:1]];
            if (keyStr.length > 0) {
                [EditorLocalizable deleteKey:keyStr atPath:self.defaultLocalizableFilePath andComplete:^(BOOL success) {
                    if (success) {
                        NSRange rangeInDocument = NSMakeRange(lineRange.location + localizedMatch.range.location + stringResult.range.location, stringResult.range.length);
                        if ([textView shouldChangeTextInRange:rangeInDocument replacementString:@""]) {
                            [textView.textStorage replaceCharactersInRange:rangeInDocument
                                                      withAttributedString:[[NSAttributedString alloc] initWithString:@""]];
                            [textView didChangeText];
                        }
                    }
                    else{
                        [Logger info:@"delete key[%@] fail", keyStr];
                    }
                }];
            }
            
        }
    }
}

-(void) chooseLocalizableFile{
    [EditorLocalizable  chooseFileLocalizableString];
}

- (void)extractLocalization {
    RCIDESourceCodeDocument *document = [RCXcode currentSourceCodeDocument];
    NSTextView *textView = [RCXcode currentSourceCodeTextView];
    if (!document || !textView) {
        return;
    }
    
    NSString * fileExtesion = [[document.displayName componentsSeparatedByString:@"."] objectAtIndex:1];
    [self setupParamsForFileExt:fileExtesion];
    
    [self searchStringAndCallWindowToEdit:textView];
}

- (void)searchStringAndCallWindowToEdit:(NSTextView *)textView{
    NSArray *selectedRanges = [textView selectedRanges];
    __strong ExtractLocalization * strongSelf = self;
    if ([selectedRanges count] > 0) {
        NSRange range = [[selectedRanges objectAtIndex:0] rangeValue];
        NSRange lineRange = [textView.textStorage.string lineRangeForRange:range];
        NSString *line = [textView.textStorage.string substringWithRange:lineRange];
        
        NSRegularExpression *localizedRex = [[NSRegularExpression alloc] initWithPattern:defaultStringLocalizeRegex options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *localizedMatches = [localizedRex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
        
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:defaultStringRegex options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
        __block NSUInteger addedLength = 0;
        
        BOOL needShowEditWindow = [localizedMatches count] > 0;
        
        if ([matches count] > 0) {
            for (int i = 0; i < [matches count]; i++) {
                NSTextCheckingResult *result = [matches objectAtIndex:i];
                NSRange matchedRangeInLine = result.range;
                NSRange matchedRangeInDocument = NSMakeRange(lineRange.location + matchedRangeInLine.location + addedLength, matchedRangeInLine.length);
                if ([self isRange:matchedRangeInLine inSkipedRanges:localizedMatches]) {
                    continue;
                }
                needShowEditWindow = NO;
                NSRange groupRange = [result rangeAtIndex:1];
                NSString *string = [line substringWithRange:groupRange];
                ItemLocalizable *aItem = [[ItemLocalizable alloc] initWithKey:nil andValue:string];
                _extractLocationWindowController =  [[ExtractLocalizationWindowController alloc]initWithItem:aItem type:ELWindowTypeNew];
                [_extractLocationWindowController showWindow];
                __weak ExtractLocalizationWindowController *weakWC = _extractLocationWindowController;
                _extractLocationWindowController.extractLocalizationDidConfirm = ^(ItemLocalizable * item) {
                    @try {
                        [EditorLocalizable saveItemLocalizable:item toPath:strongSelf.defaultLocalizableFilePath];
                        NSString *outputString = [NSString stringWithFormat:defaultStringLocalizeFormat, item.key];
                        addedLength = addedLength + outputString.length - string.length;
                        if ([textView shouldChangeTextInRange:matchedRangeInDocument replacementString:outputString]) {
                            [textView.textStorage replaceCharactersInRange:matchedRangeInDocument
                                                      withAttributedString:[[NSAttributedString alloc] initWithString:outputString]];
                            [textView didChangeText];
                        }
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Save Item Localizable fail %@", exception);
                    }
                    [weakWC close];
                };
                break;
            }
        }
        
        if(needShowEditWindow){
            NSTextCheckingResult *stringMatch = [matches firstObject];
            NSString *key = [line substringWithRange:[stringMatch rangeAtIndex:1]];
            NSString *val = [EditorLocalizable valueForLocalizationKey:key atPath:self.defaultLocalizableFilePath];
            if (val.length <= 0) {
                return;
            }
            ItemLocalizable *aItem = [[ItemLocalizable alloc] initWithKey:key andValue:val];
            _extractLocationWindowController =  [[ExtractLocalizationWindowController alloc]initWithItem:aItem type:ELWindowTypeEdit];
            [_extractLocationWindowController showWindow];
            __weak ExtractLocalizationWindowController *weakWC = _extractLocationWindowController;
            _extractLocationWindowController.extractLocalizationDidConfirm = ^(ItemLocalizable * item) {
                @try {
                    [EditorLocalizable saveItemLocalizable:item toPath:strongSelf.defaultLocalizableFilePath];
                }
                @catch (NSException *exception) {
                    NSLog(@"Save Item Localizable fail %@", exception);
                }
                [weakWC close];
            };
        }
    }
}

- (BOOL)isRange:(NSRange)range inSkipedRanges:(NSArray *)ranges {
    for (int i = 0; i < [ranges count]; i++) {
        NSTextCheckingResult *result = [ranges objectAtIndex:i];
        NSRange skippedRange = result.range;
        if (skippedRange.location <= range.location && skippedRange.location + skippedRange.length > range.location + range.length) {
            return YES;
        }
    }
    return NO;
}

@end

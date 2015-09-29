//
//  Lin.m
//  Lin
//
//  Created by Katsuma Tanaka on 2015/02/05.
//  Copyright (c) 2015年 Katsuma Tanaka. All rights reserved.
//

#import "Lin.h"

// Xcode
#import "Xcode.h"

// Models
#import "LINLocalizationParser.h"
#import "LINLocalization.h"
#import "LINTextCompletionItem.h"

// ExtractLocalization
#import "ExtractLocalization.h"

static id _sharedInstance = nil;

@interface Lin ()

@property (nonatomic, copy) NSArray *configurations;
@property (nonatomic, strong) LINLocalizationParser *parser;
@property (nonatomic, strong) NSMutableDictionary *completionItems;
@property (nonatomic, strong) NSOperationQueue *indexingQueue;

@end

@implementation Lin

+ (void)pluginDidLoad:(NSBundle *)bundle
{
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedInstance = [self new];
    });
}

+ (instancetype)sharedInstance
{
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // Load configurations
        NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Completions" ofType:@"plist"];
        self.configurations = [NSArray arrayWithContentsOfFile:filePath];
        
        self.parser = [LINLocalizationParser new];
        self.completionItems = [NSMutableDictionary dictionary];
        
        // Create indexing queue
        NSOperationQueue *indexingQueue = [NSOperationQueue new];
        indexingQueue.maxConcurrentOperationCount = 1;
        self.indexingQueue = indexingQueue;
        
        // Create ExtractLocalization Menu
        [self addMenu];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(menuDidChange:)
                                                     name: NSMenuDidChangeItemNotification
                                                   object: nil];
    }
    
    return self;
}

- (void)addMenu
{
    [[ExtractLocalization sharedInstance] createMenuExtractLocalization];
}


- (void) menuDidChange: (NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSMenuDidChangeItemNotification
                                                  object: nil];
    
    [self addMenu];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(menuDidChange:)
                                                 name: NSMenuDidChangeItemNotification
                                               object: nil];
}

#pragma mark - Indexing Localizations

- (void)indexNeedsUpdate:(IDEIndex *)index
{
    IDEWorkspace *workspace = [index valueForKey:@"_workspace"];
    NSString *workspaceFilePath = workspace.representingFilePath.pathString;
    if (workspaceFilePath == nil) return;
    
    // Add indexing operation
    NSBlockOperation *operation = [NSBlockOperation new];
    
    __weak __typeof(self) weakSelf = self;
    __weak NSBlockOperation *weakOperation = operation;
    
    [operation addExecutionBlock:^{
        // Find strings files
        IDEIndexCollection *indexCollection = [index filesContaining:@".strings" anchorStart:NO anchorEnd:NO subsequence:NO ignoreCase:YES cancelWhen:nil];
        
        if ([weakOperation isCancelled]) return;
        
        // Classify localizations by key
        NSMutableDictionary *localizationsByKey = [NSMutableDictionary dictionary];
        
        for (DVTFilePath *filePath in indexCollection) {
            if ([weakOperation isCancelled]) return;
            
            NSArray *pathComponents = [filePath pathComponents];
            NSString *languageDesignation = [[pathComponents objectAtIndex:pathComponents.count - 2] stringByDeletingPathExtension];
            // Process only zh_CN
            if (![languageDesignation isEqualTo:@"zh_CN"]) {
                continue;
            }
            
            NSArray *parsedLocalizations = [self.parser localizationsFromContentsOfFile:filePath.pathString];
            
            for (LINLocalization *localization in parsedLocalizations) {
                NSMutableArray *localizations = localizationsByKey[localization.key];
                
                if (localizations) {
                    [localizations addObject:localization];
                } else {
                    localizations = [NSMutableArray array];
                    [localizations addObject:localization];
                    localizationsByKey[localization.key] = localizations;
                }
            }
        }
        
        if ([weakOperation isCancelled]) return;
        
        // Convert localizations to completions
        NSMutableArray *completionItems = [NSMutableArray array];
        
        for (NSString *key in [localizationsByKey allKeys]) {
            if ([weakOperation isCancelled]) return;
            
            NSMutableArray *localizations = localizationsByKey[key];
            
            // Sort localizations
            [localizations sortUsingComparator:^NSComparisonResult(LINLocalization *lhs, LINLocalization *rhs) {
                return [[lhs languageDesignation] caseInsensitiveCompare:[rhs languageDesignation]];
            }];
            
            // Create completion item
            LINTextCompletionItem *completionItem = [[LINTextCompletionItem alloc] initWithLocalizations:localizations];
            [completionItems addObject:completionItem];
        }
        
        if ([weakOperation isCancelled]) return;
        
        // Sort completions
        [completionItems sortUsingComparator:^NSComparisonResult(LINTextCompletionItem *lhs, LINTextCompletionItem *rhs) {
            return [[lhs key] caseInsensitiveCompare:[rhs key]];
        }];
        
        if ([weakOperation isCancelled]) return;
        
        weakSelf.completionItems[workspaceFilePath] = completionItems;
    }];
    
    [self.indexingQueue cancelAllOperations];
    [self.indexingQueue addOperation:operation];
}


#pragma mark - Auto Completion

- (NSArray *)completionItemsForWorkspace:(IDEWorkspace *)workspace
{
    NSString *workspaceFilePath = workspace.representingFilePath.pathString;
    if (workspaceFilePath == nil) return nil;
    
    return self.completionItems[workspaceFilePath];
}

- (BOOL)shouldAutoCompleteInTextView:(DVTCompletingTextView *)textView
{
    NSRange keyRange = [self replacableKeyRangeInTextView:textView];
    return (keyRange.location != NSNotFound);
}

- (NSRange)replacableKeyRangeInTextView:(DVTCompletingTextView *)textView
{
    if (textView == nil) return NSMakeRange(NSNotFound, 0);
    
    DVTTextStorage *textStorage = (DVTTextStorage *)textView.textStorage;
    DVTSourceCodeLanguage *language = textStorage.language;
    NSString *string = textStorage.string;
    NSRange selectedRange = textView.selectedRange;
    
    for (NSDictionary *configuration in self.configurations) {
        for (NSDictionary *patterns in configuration[@"LINKeyCompletionPatterns"]) {
            NSString *pattern = patterns[language.languageName];
            
            if (pattern && pattern.length > 0) {
                NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
                NSArray *matches = [regularExpression matchesInString:string options:0 range:NSMakeRange(0, string.length)];
                
                for (NSTextCheckingResult *match in matches) {
                    if (match.numberOfRanges == 0) continue;
                    NSRange keyRange = [match rangeAtIndex:match.numberOfRanges - 1];
                    
                    if (NSMaxRange(keyRange) == NSMaxRange(selectedRange)) {
                        return keyRange;
                    }
                }
            }
        }
    }
    
    return NSMakeRange(NSNotFound, 0);
}

- (NSRange)replacableTableNameRangeInTextView:(DVTCompletingTextView *)textView
{
    if (textView == nil) return NSMakeRange(NSNotFound, 0);
    
    DVTTextStorage *textStorage = (DVTTextStorage *)textView.textStorage;
    DVTSourceCodeLanguage *language = textStorage.language;
    NSString *string = textStorage.string;
    NSRange selectedRange = textView.selectedRange;
    
    for (NSDictionary *configuration in self.configurations) {
        for (NSDictionary *patterns in configuration[@"LINTableNameCompletionPatterns"]) {
            NSString *pattern = patterns[language.languageName];
            
            if (pattern && pattern.length > 0) {
                NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
                NSArray *matches = [regularExpression matchesInString:string options:0 range:NSMakeRange(0, string.length)];
                
                for (NSTextCheckingResult *match in matches) {
                    if (match.numberOfRanges == 0) continue;
                    NSRange tableNameRange = [match rangeAtIndex:match.numberOfRanges - 1];
                    
                    if (NSLocationInRange(selectedRange.location, match.range)) {
                        return tableNameRange;
                    }
                }
            }
        }
    }
    
    return NSMakeRange(NSNotFound, 0);
}

@end

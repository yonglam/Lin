#import "EditorLocalizable.h"
#import "FileHelper.h"
#import "Logger.h"
#import "ExtractLocalization.h"

const static NSString * kEditorLocalizableFilePathLocalizable = @"kEditorLocalizableFilePathLocalizable";

@implementation EditorLocalizable

+(NSString *) defaultPathLocalizablePath{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * filePath = [defaults objectForKey:[kEditorLocalizableFilePathLocalizable copy]];
    if (filePath) {
        return filePath;
    }
    
    NSString * defaultNameOfFileLocalizable = [self getCurrentDefaultNameOfFileLocalizable];
    NSArray * filesFounded = [FileHelper recursivePathsForResourcesOfType:defaultNameOfFileLocalizable
                                                              inDirectory:[self getRootProjectPath]];
    NSString * language = [self getDefaultLanguage];
    NSString * defaultFileLocalization  = nil;
    if ([filesFounded count] > 0) {
        defaultFileLocalization = [filesFounded objectAtIndex:0];
        defaultFileLocalization = [defaultFileLocalization
                                   stringByReplacingOccurrencesOfString:language
                                   withString:[NSString stringWithFormat:@"/%@",language]];
    }
    [Logger info:@"Default localizable path %@",defaultFileLocalization];
    return defaultFileLocalization;
}

+(NSString *) getWorkSpacePathProject{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
    id workSpace;
    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
            workSpace = [controller valueForKey:@"_workspace"];
        }
    }
    NSString *workspacePath = [[workSpace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    workspacePath = [self removeStrings:workspacePath andArrayOfStringsToRemove:@[@".xcodeproj", @".xcworkspace"]];
    [Logger info:@"Workspace path %@",workspacePath];
    return workspacePath;
}

+(NSString *) getRootProjectPath{
    NSString * workSpace = [self getWorkSpacePathProject];
    NSArray * workSpaceSplit = [workSpace componentsSeparatedByString:@"/"];
    NSMutableString * rootProjectPath = [[NSMutableString alloc] init];
    for (int i = 0; i < [workSpaceSplit count] -1; i++) {
        [rootProjectPath appendFormat:@"%@/",[workSpaceSplit objectAtIndex:i]];
    }
    [Logger info:@"Root project path %@",rootProjectPath];
    return rootProjectPath;
}

+(NSString *) getCurrentDefaultNameOfFileLocalizable{
//    return [NSString stringWithFormat:@"%@/Localizable.strings",[self getDefaultLanguage]];
    return [NSString stringWithFormat:@"%@/mm.strings",[self getDefaultLanguage]];
}

+(NSString *) getDefaultLanguage{
    NSString *workspacePath = [self getWorkSpacePathProject];
    NSString * nameProject = [self getCurrentNameProject];
    NSString * plistNameFile = nil;
    
    if ([ExtractLocalization isSwift]) {
        plistNameFile = [NSString stringWithFormat:@"%@/Info.plist",workspacePath];
    }else{
        plistNameFile = [NSString stringWithFormat:@"%@/%@-Info.plist",workspacePath,nameProject];
    }
//    NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistNameFile];
//    NSString * language = [NSString stringWithFormat:@"%@.lproj",[plistDict objectForKey:@"CFBundleDevelopmentRegion"]];
    NSString * language = [NSString stringWithFormat:@"%@.lproj",@"zh_CN"];
    [Logger info:@"Language %@",language];
    return language;
}

+(NSString *) getCurrentNameProject{
    NSString * nameProjectWithExtenstion = [[[self getWorkSpacePathProject]
                                             componentsSeparatedByString:@"/"] lastObject];
    NSString * nameProject = [self removeStrings:nameProjectWithExtenstion
                       andArrayOfStringsToRemove:@[@".xcodeproj", @".xcworkspace"]];
    [Logger info:@"Name project %@",nameProject];
    return nameProject;
}

+ (void)doTreatmentError:(NSError *)error itemLocalizable:(ItemLocalizable *)itemLocalizable{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Localization Error"];
    NSString *errMsg = error.userInfo[@"msg"];
    [alert setInformativeText:errMsg.length > 0 ? errMsg : error.localizedDescription];
//    [alert addButtonWithTitle:@"Choose localizable file"];
    [alert setAlertStyle:NSCriticalAlertStyle];
    NSInteger result =  [alert runModal];
//    if (result == NSAlertSecondButtonReturn ) {
//        NSString * file =  [self chooseFileLocalizableString];
//        if (file != nil) {
//            [self saveItemLocalizable:itemLocalizable toPath:file];
//        }else{
//            [NSException raise:@"Save item localizable fail" format:@"Save item localizable fail %@", error];
//        }
//    }
    if (result == NSAlertFirstButtonReturn ){
        [NSException raise:@"Save item localizable fail" format:@"Save item localizable fail %@", error];
    }
}

+(void) saveItemLocalizable:(ItemLocalizable *)itemLocalizable
                     toPath:(NSString *) toPath{
    NSError * error = nil;
    
    NSString * keyAndValue = [NSString stringWithFormat:@"\n\"%@\" = \"%@\";",itemLocalizable.key,itemLocalizable.value];
    NSString *contents = [NSString stringWithContentsOfFile:toPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
    NSString *keyPattern = [NSString stringWithFormat:@"\"%@\"\\s*=", itemLocalizable.key];
    NSTextCheckingResult *keyResult = [self resultOfPattern:keyPattern in:contents];
    if (keyResult && keyResult.range.location != NSNotFound) {
        NSRange keyLineRange = [contents lineRangeForRange:keyResult.range];
        contents = [contents stringByReplacingCharactersInRange:keyLineRange withString:@""];
        [Logger info:@"delete key[%@]", itemLocalizable.key];
    }
    
    NSString *sessionPattern = [NSString stringWithFormat:@"session:\\s*%@", itemLocalizable.session];
    NSTextCheckingResult *sessionResult = [self resultOfPattern:sessionPattern in:contents];
    if (itemLocalizable.session.length <= 0 || (!sessionResult) || (sessionResult.range.location == NSNotFound)) {
        contents = [contents stringByAppendingString:keyAndValue];
    }
    else{
        NSRange lineRange = [contents lineRangeForRange:sessionResult.range];
        NSMutableString *mutableContents = [NSMutableString stringWithString:contents];
        [mutableContents replaceCharactersInRange:NSMakeRange(lineRange.location + lineRange.length - 1, 0) withString:keyAndValue];
        contents = [NSString stringWithString:mutableContents];
    }
    [contents writeToFile:toPath atomically:YES encoding: NSUTF8StringEncoding error:&error];
    if(error) {
        [self doTreatmentError:error itemLocalizable:itemLocalizable];
    }
}

+ (NSTextCheckingResult *)resultOfPattern:(NSString *)pattern in:(NSString *)contents
{
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *result = [regExp firstMatchInString:contents options:0 range:NSMakeRange(0, contents.length)];
    return result;
}

+ (NSArray *)resultsOfPattern:(NSString *)pattern in:(NSString *)contents
{
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *results = [regExp matchesInString:contents options:0 range:NSMakeRange(0, contents.length)];
    return results;
}

+(NSString *) chooseFileLocalizableString{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO]; // yes if more than one dir is allowed
    [panel setAllowedFileTypes:@[@"strings"]];
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        if ([[panel URLs] count] > 0) {
            NSURL * path  = [[panel URLs] objectAtIndex:0];
            NSString * filePath  = [[[path  filePathURL] description] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:filePath forKey:[kEditorLocalizableFilePathLocalizable copy]];
            [defaults synchronize];
            return filePath;
        }
    }
    return nil;
}

+(NSString * )removeStrings:(NSString *)string andArrayOfStringsToRemove:(NSArray *)stringsToRemove{
    for (NSString * toRemove  in stringsToRemove) {
        string = [string stringByReplacingOccurrencesOfString:toRemove
                                                   withString:@""];
    }
    return string;
}

+ (NSArray *)sessionArrayOfPath:(NSString *)path
{
    NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSString *sessionPattern = @"session:\\s*([a-zA-Z]*)\\s*";
    NSArray *matchs = [self resultsOfPattern:sessionPattern in:contents];
    NSMutableArray *sessions = [NSMutableArray arrayWithCapacity:[matchs count]];
    for (NSTextCheckingResult *match in matchs) {
        if ([match numberOfRanges] > 1) {
            NSString *session = [contents substringWithRange:[match rangeAtIndex:1]];
            [sessions addObject:session];
        }
    }
    return sessions;
}

@end

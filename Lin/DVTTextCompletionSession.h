//
//  DVTTextCompletionSession.h
//  Lin
//
//  Created by Katsuma Tanaka on 2015/03/27.
//  Copyright (c) 2015年 Katsuma Tanaka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVTTextCompletionSession : NSObject

@property (retain) NSArray *filteredCompletionsAlpha;
@property (nonatomic) long long selectedCompletionIndex;

@end

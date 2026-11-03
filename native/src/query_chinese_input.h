#pragma once
#import "query_english_input.h"
#import "mandarin_pinyin.h"

static inline BOOL QueryContainsChinese(NSString *text) {
  // Unicode Han includes traditional, compatibility and supplementary ideographs.
  return text.length && [text rangeOfString:@"\\p{sc=Han}"
      options:NSRegularExpressionSearch].location != NSNotFound;
}

static inline NSString *QueryChineseText(NSString *query) {
  // The explicit English command retains precedence for mixed-language sentences.
  return QueryEnglishText(query) == nil && QueryContainsChinese(query) ? query : nil;
}

static inline NSString *QueryLiteralText(NSString *query) {
  return QueryEnglishText(query) ?: QueryChineseText(query);
}

static inline BOOL QueryLiteralEntry(NSString *query) {
  return QueryEnglishEntry(query) || QueryChineseText(query) != nil;
}

static inline NSString *QueryLiteralPronunciation(NSString *query, NSString *translation) {
  return QueryChineseText(query) ?: (QueryEnglishText(query) != nil ? translation : nil);
}

static inline void QueryLiteralRows(NSString *query, NSMutableArray<NSString *> *candidates,
                             NSMutableArray<NSString *> *comments) {
  NSString *literal = QueryLiteralText(query);
  if (literal == nil) return;
  NSString *chinese = QueryChineseText(query);
  [candidates setArray:@[literal.length ? literal : @"English → 中文"]];
  [comments setArray:@[chinese ? MandarinPinyinString(chinese) :
      literal.length ? @"" : @"Type English after uen "]];
}

static inline NSString *QueryNormalizedPaste(NSString *pasted) {
  NSMutableString *normalized = [NSMutableString string];
  for (NSUInteger index = 0; index < pasted.length; ++index) {
    unichar character = [pasted characterAtIndex:index];
    if (character == '\r' || character == '\n' || character == '\t')
      character = ' ';
    if ([NSCharacterSet.controlCharacterSet characterIsMember:character]) continue;
    [normalized appendFormat:@"%C", character];
  }
  return normalized;
}

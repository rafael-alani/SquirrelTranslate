#pragma once
#import <Foundation/Foundation.h>

// The explicit prefix prevents English sentences from entering the pinyin engine.
static NSString *QueryEnglishText(NSString *query) {
  if (![query hasPrefix:@"en "]) return nil;
  return [[query substringFromIndex:3]
      stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static BOOL QueryEnglishEntry(NSString *query) {
  return [query isEqualToString:@"en"] || QueryEnglishText(query) != nil;
}

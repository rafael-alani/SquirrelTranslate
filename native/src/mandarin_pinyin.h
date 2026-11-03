#pragma once

#include <CoreFoundation/CoreFoundation.h>

// Owned result shared by the Objective-C panel and C++ translation service.
static inline CFStringRef CreateMandarinPinyin(CFStringRef source) {
  if (!source) return NULL;
  CFMutableStringRef latin = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, source);
  if (!latin) return NULL;
  if (CFStringTransform(latin, NULL, kCFStringTransformMandarinLatin, false))
    return latin;
  CFRelease(latin);
  return NULL;
}

#ifdef __OBJC__
#import <Foundation/Foundation.h>
static inline NSString *MandarinPinyinString(NSString *text) {
  return CFBridgingRelease(CreateMandarinPinyin((__bridge CFStringRef)text)) ?: @"";
}
#endif

#ifdef __cplusplus
#include <string>
#include <vector>

// Local Mandarin transliteration keeps tone marks and needs no provider call.
inline std::string MandarinPinyin(const std::string& text) {
  CFStringRef source = CFStringCreateWithBytes(kCFAllocatorDefault,
      reinterpret_cast<const UInt8*>(text.data()), text.size(),
      kCFStringEncodingUTF8, false);
  if (!source) return {};
  CFStringRef latin = CreateMandarinPinyin(source);
  CFRelease(source);
  if (!latin) return {};
  std::string result;
  std::vector<char> buffer(CFStringGetMaximumSizeForEncoding(
      CFStringGetLength(latin), kCFStringEncodingUTF8) + 1);
  if (CFStringGetCString(latin, buffer.data(), buffer.size(), kCFStringEncodingUTF8))
    result = buffer.data();
  CFRelease(latin);
  return result;
}
#endif

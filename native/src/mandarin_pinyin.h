#pragma once

#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>

// Local Mandarin transliteration keeps tone marks and needs no provider call.
inline std::string MandarinPinyin(const std::string& text) {
  CFStringRef source = CFStringCreateWithBytes(kCFAllocatorDefault,
      reinterpret_cast<const UInt8*>(text.data()), text.size(),
      kCFStringEncodingUTF8, false);
  if (!source) return {};
  CFMutableStringRef latin = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, source);
  CFRelease(source);
  if (!latin) return {};
  std::string result;
  if (CFStringTransform(latin, nullptr, kCFStringTransformMandarinLatin, false)) {
    std::vector<char> buffer(CFStringGetMaximumSizeForEncoding(
        CFStringGetLength(latin), kCFStringEncodingUTF8) + 1);
    if (CFStringGetCString(latin, buffer.data(), buffer.size(), kCFStringEncodingUTF8))
      result = buffer.data();
  }
  CFRelease(latin);
  return result;
}

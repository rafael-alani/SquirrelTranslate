#import "../src/query_english_input.h"
#include <assert.h>

int main(void) {
  @autoreleasepool {
    assert(QueryEnglishText(@"nihao") == nil);
    assert(QueryEnglishText(@"en") == nil);
    assert(QueryEnglishEntry(@"en")); // Space enters the mode instead of copying.
    assert([QueryEnglishText(@"en ") isEqualToString:@""]);
    assert([QueryEnglishText(@"en Hello, how are you?")
        isEqualToString:@"Hello, how are you?"]);
    assert([QueryEnglishText(@"en   I'm learning Chinese! ")
        isEqualToString:@"I'm learning Chinese!"]);
    assert([QueryEnglishText(@"en Happy 2026 — café")
        isEqualToString:@"Happy 2026 — café"]);
    assert(!QueryEnglishEntry(@"english"));
    assert(!QueryEnglishEntry(@"e")); // Backspace exits the command prefix.
  }
}

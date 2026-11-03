#import "query_chinese_input.h"
#include <assert.h>

static NSString *query_text;
static BOOL query_active = YES;
static int query_session = 1, engine_calls, generations, repaints;
static void AdvanceQueryGeneration(void) { ++generations; }
static void ShowQueryContext(void) { ++repaints; }
static BOOL SetInput(int session, const char *input) {
  assert(session == 1 && strcmp(input, "fen1ke4") == 0);
  ++engine_calls;
  return YES;
}
static BOOL ProcessKey(int session, int key, int modifiers) {
  assert(session == 1 && key == 0xff54 && modifiers == 0);
  ++engine_calls;
  return YES;
}
static struct {
  BOOL (*set_input)(int, const char *);
  BOOL (*process_key)(int, int, int);
} api = {SetInput, ProcessKey}, *query_api = &api;
#define RIME_PROVIDED(api, member) ((api)->member != NULL)
#include "query_routing_under_test.inc"

int main(void) {
  @autoreleasepool {
    assert(!QueryContainsChinese(@"fen1ke4"));
    assert(!QueryContainsChinese(@"，。！？"));
    assert(QueryContainsChinese(@"課程"));
    assert(QueryContainsChinese(@"𠮷"));
    assert(QueryContainsChinese(@"〇"));
    assert(QueryLiteralText(@"fen1ke4") == nil);
    assert(QueryLiteralEntry(@"en"));
    assert(!QueryLiteralEntry(@"english"));
    assert(QueryChineseText(@"en Learn 中文!") == nil);
    assert([QueryLiteralText(@"en Learn 中文!") isEqualToString:@"Learn 中文!"]);
    assert([QueryNormalizedPaste(@"分课\n你好，\t世界！\a")
        isEqualToString:@"分课 你好， 世界！"]);

    NSMutableArray *candidates = [NSMutableArray arrayWithObject:@"stale Rime candidate"];
    NSMutableArray *comments = [NSMutableArray arrayWithObject:@"old comment"];
    for (NSString *source in @[@"分课", @" 你好， 世界！ ", @"我正在学习中文。", @"課程", @"𠮷"]) {
      query_text = source;
      assert([QueryChineseText(source) isEqualToString:source]);
      assert(QueryLiteralEntry(source)); // Spaces/paging/letter runs stay literal.
      QueryLiteralRows(source, candidates, comments);
      assert(candidates.count == 1 && [candidates[0] isEqualToString:source]);
      assert(comments.count == 1 && [comments[0] isEqualToString:MandarinPinyinString(source)]);
      assert(SetQueryInput(source));
      assert(ProcessQueryKey(0xff54));
      assert([QueryTargetForCandidate(source) isEqualToString:@"en"]);
    }
    assert([QueryLiteralPronunciation(@"分课", @"lessons") isEqualToString:@"分课"]);
    assert([QueryLiteralPronunciation(@"en Hello", @"你好") isEqualToString:@"你好"]);
    assert(QueryLiteralPronunciation(@"fen1ke4", @"lessons") == nil);
    assert([MandarinPinyinString(@"分课") isEqualToString:@"fēn kè"]);
    assert([MandarinPinyinString(@"你好，世界！") containsString:@"nǐ hǎo"]);
    assert(engine_calls == 0 && generations == 0 && repaints == 0);

    // The English mode still bypasses Rime and translates the source to Chinese.
    query_text = @"en Hello, how are you?";
    QueryLiteralRows(query_text, candidates, comments);
    assert([candidates[0] isEqualToString:@"Hello, how are you?"]);
    assert([comments[0] isEqualToString:@""]); // Pinyin waits for the Chinese result.
    assert(SetQueryInput(query_text) && ProcessQueryKey(0xff54));
    assert(engine_calls == 0);
    assert([QueryTargetForCandidate(candidates[0]) isEqualToString:@"zh-CN"]);

    // Deleting literal text returns to the existing pinyin engine and navigation.
    query_text = @"fen1ke4";
    QueryLiteralRows(query_text, candidates, comments);
    assert([candidates[0] isEqualToString:@"Hello, how are you?"]); // No replacement.
    assert(SetQueryInput(query_text) && ProcessQueryKey(0xff54));
    assert(engine_calls == 2 && generations == 1 && repaints == 1);
    assert([QueryTargetForCandidate(@"分课") isEqualToString:@"en"]);
    assert([QueryTargetForCandidate(@"study") isEqualToString:@"zh-CN"]);
  }
}

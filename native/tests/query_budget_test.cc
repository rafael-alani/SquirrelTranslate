#include "../src/query_translation_service.h"
#include "../src/public_translation_providers.h"
#include "../src/mandarin_pinyin.h"
#include <cassert>
#include <chrono>
#include <condition_variable>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <thread>
#include <unistd.h>

using namespace std::chrono_literals;
static std::mutex mutex;
static std::condition_variable ready;
static int calls = 0, callbacks = 0;
static std::string last_word, last_translation, last_phonetic;

namespace squirrel_translate_public {
std::string Fetch(const std::string&, const Request& request, const ProviderConfig&) {
  std::lock_guard<std::mutex> lock(mutex);
  ++calls;
  last_word = request.word;
  return request.target == "zh-CN" ? "学习" : "study";
}
std::string FetchMacDictionaryPhonetic(const std::string&) { return {}; }
}

static void Result(uint64_t, const char*, const char*, const char* translation,
                   const char* phonetic, void*) {
  std::lock_guard<std::mutex> lock(mutex);
  ++callbacks;
  last_translation = translation;
  last_phonetic = phonetic;
  ready.notify_all();
}

static void Request(const char* word, uint64_t generation, const char* target = "zh-CN") {
  SquirrelQueryTranslationRequest(word, target, generation, Result, nullptr);
}

int main() {
  char root[] = "/tmp/squirrel-budget-XXXXXX";
  assert(mkdtemp(root));
  assert(setenv("HOME", root, 1) == 0);
  const auto rime = std::filesystem::path(root) / "Library/Rime";
  std::filesystem::create_directories(rime);
  std::ofstream(rime / "translation.providers.yaml") <<
      "providers:\n  mac_dictionary:\n    enabled: true\n";

  assert(MandarinPinyin("学习") == "xué xí");
  assert(MandarinPinyin("你好，世界！").find("nǐ hǎo") == 0);
  assert(MandarinPinyin("").empty());
  assert(MandarinPinyin(std::string(1, '\xff')).empty());
  for (uint64_t generation = 1; generation <= 2; ++generation) {
    SquirrelQueryTranslationSetGeneration(generation);
    Request("unfinished", generation);
    std::this_thread::sleep_for(450ms);
    std::lock_guard<std::mutex> lock(mutex);
    assert(calls == 0); // The former 300 ms debounce spends quota here.
  }
  SquirrelQueryTranslationSetGeneration(3);
  Request("study", 3);
  Request("study", 3); // Repaints must not duplicate a queued/in-flight lookup.
  {
    std::unique_lock<std::mutex> lock(mutex);
    assert(ready.wait_for(lock, 3s, [] { return callbacks == 1; }));
    assert(calls == 1 && last_word == "study");
    assert(last_translation == "学习" && last_phonetic == "xué xí");
  }
  SquirrelQueryTranslationSetGeneration(4);
  Request("study", 4); // Reopening the same lookup uses the completed cache.
  {
    std::lock_guard<std::mutex> lock(mutex);
    assert(calls == 1 && callbacks == 2);
  }
  Request("study", 4, "en"); // Direction is part of the cache key.
  {
    std::unique_lock<std::mutex> lock(mutex);
    assert(ready.wait_for(lock, 3s, [] { return callbacks == 3; }));
    assert(calls == 2 && last_translation == "study" && last_phonetic.empty());
  }
  SquirrelQueryTranslationSetGeneration(5);
  Request("closed before the delay", 5);
  SquirrelQueryTranslationSetGeneration(6);
  std::this_thread::sleep_for(1100ms);
  {
    std::lock_guard<std::mutex> lock(mutex);
    assert(calls == 2 && callbacks == 3);
  }
  SquirrelQueryTranslationShutdown();
  std::filesystem::remove_all(root);
}

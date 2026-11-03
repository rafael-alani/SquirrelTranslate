add_executable(query-budget-checks "${CMAKE_CURRENT_LIST_DIR}/query_budget_test.cc"
  "${SOURCE_DIR}/query_translation_service.cc")
target_compile_features(query-budget-checks PRIVATE cxx_std_17)
target_compile_options(query-budget-checks PRIVATE -UNDEBUG)
target_link_libraries(query-budget-checks PRIVATE "-framework CoreFoundation")
add_test(NAME query_budget_and_pinyin COMMAND query-budget-checks)
add_executable(query-english-checks "${CMAKE_CURRENT_LIST_DIR}/query_english_test.m")
target_compile_options(query-english-checks PRIVATE -fobjc-arc -UNDEBUG)
target_link_libraries(query-english-checks PRIVATE "-framework Foundation")
add_test(NAME query_english_input COMMAND query-english-checks)

# Exercise the real routing guards without loading the bridge/event tap or Rime.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  "${SOURCE_DIR}/squirrel_query_bridge.m")
file(READ "${SOURCE_DIR}/squirrel_query_bridge.m" _bridge_source)
set(_routing_source "")
foreach(_anchors IN ITEMS
    "static NSString *QueryTargetForCandidate|static void QueryTranslationDidFinish"
    "static BOOL ProcessQueryKey(int keycode) {|static void ConfigureQuerySession"
    "static BOOL SetQueryInput(NSString *input) {|static BOOL FeedQueryInputByKeys")
  string(REPLACE "|" ";" _bounds "${_anchors}")
  list(GET _bounds 0 _start_anchor)
  list(GET _bounds 1 _end_anchor)
  string(FIND "${_bridge_source}" "${_start_anchor}" _start)
  string(FIND "${_bridge_source}" "${_end_anchor}" _end)
  if(_start LESS 0 OR _end LESS_EQUAL _start)
    message(FATAL_ERROR "Cannot locate query routing test boundaries")
  endif()
  math(EXPR _length "${_end} - ${_start}")
  string(SUBSTRING "${_bridge_source}" ${_start} ${_length} _snippet)
  string(APPEND _routing_source "${_snippet}\n")
endforeach()
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/query_routing_under_test.inc" "${_routing_source}")
add_executable(query-chinese-checks "${CMAKE_CURRENT_LIST_DIR}/query_chinese_test.m")
target_include_directories(query-chinese-checks PRIVATE "${SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}")
target_compile_options(query-chinese-checks PRIVATE -fobjc-arc -UNDEBUG)
target_link_libraries(query-chinese-checks PRIVATE "-framework Foundation")
add_test(NAME query_direct_chinese COMMAND query-chinese-checks)

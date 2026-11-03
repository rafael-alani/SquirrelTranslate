# Extract only the pure unit parser; never load the UI bridge in a test process.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
  "${SOURCE_DIR}/squirrel_query_bridge.m")
file(READ "${SOURCE_DIR}/squirrel_query_bridge.m" _unit_source)
set(_unit_test_source "")
foreach(_anchors IN ITEMS
    "typedef NS_ENUM(NSInteger, PhoneInputStatus)|static BOOL IPv4QueryStatus"
    "static NSString *UtilityNumber|static NSArray<NSArray<NSString *> *> *RowsForTimeQuery"
    "typedef NS_ENUM(NSInteger, STUnitDimension)|typedef struct {\n  __unsafe_unretained NSString *code"
    "static NSArray<NSArray<NSString *> *> *RowsForUnitInput|static NSArray<NSArray<NSString *> *> *RowsForQuickConversions"
    "static NSArray<NSArray<NSString *> *> *RowsForQuickConversions(double value) {|static BOOL MoveColorSampleCursor"
    "static const NSInteger kQueryUtilityPageSize|static NSInteger QueryUtilityCandidateCount"
    "static CGFloat FontLineHeight|static STFocusedElementState FocusedElementState"
    "@interface STQueryBridgeViewV4|static STQueryBridgeViewV4 *QueryView")
  string(REPLACE "|" ";" _bounds "${_anchors}")
  list(GET _bounds 0 _start_anchor)
  list(GET _bounds 1 _end_anchor)
  string(FIND "${_unit_source}" "${_start_anchor}" _start)
  string(FIND "${_unit_source}" "${_end_anchor}" _end)
  if(_start LESS 0 OR _end LESS_EQUAL _start)
    message(FATAL_ERROR "Cannot locate unit parser test boundaries")
  endif()
  math(EXPR _length "${_end} - ${_start}")
  string(SUBSTRING "${_unit_source}" ${_start} ${_length} _snippet)
  string(APPEND _unit_test_source "${_snippet}\n")
endforeach()
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/generated/unit_conversion_under_test.inc"
  "${_unit_test_source}")
add_executable(unit_conversion_test "${CMAKE_CURRENT_LIST_DIR}/unit_conversion_test.m")
target_include_directories(unit_conversion_test PRIVATE
  "${CMAKE_CURRENT_BINARY_DIR}/generated" "${RIME_HEADERS}")
target_compile_options(unit_conversion_test PRIVATE -fobjc-arc -UNDEBUG -Wall -Wextra)
target_link_libraries(unit_conversion_test PRIVATE
  "-framework AppKit" "-framework ApplicationServices" "-framework CoreText")
add_test(NAME unit_conversion COMMAND unit_conversion_test)

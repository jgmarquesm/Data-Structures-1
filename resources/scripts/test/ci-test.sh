#!/bin/bash

start=$(date +%s)

HELPERS=(
ExceptionHandler
Node
Vertex
) #--H

DS=(
Array
SinglyLinkedList
DoublyLinkedList
CircularDoublyLinkedList
StaticStack
DynamicStack
StaticQueue
DynamicQueue
Matrix
UndirectedWeightedGraph
) #--DS

function _get_executed_tests() {
  execs=0
  while read -r line
  do
    e="$( echo "$line" | grep -o -P "^\d+," | rev | cut -c2- | rev )"
    (( execs=execs+$(( e )) ))
  done < ../resources/scripts/test/tests_result.txt
  echo "$execs"
}

function _get_failed_tests() {
  fail=0
  while read -r line
  do
    f="$( echo "$line" | grep -o -P ",\d+$" | cut -c2-)"
    (( fail=fail+$(( f )) ))
  done < ../resources/scripts/test/tests_result.txt
  echo "$fail"
}

function _parse_test_result() {
  sed -i~ -E 's/(.+) Tests (.+) Failures/\1,\2/g' ../resources/scripts/test/tests_result.txt
}

function _title_case_to_snake_case() {
 # shellcheck disable=SC2001
 sed 's/[A-Z]/_\l&/g' <<<"${1}" | cut -c2-
}

function set_suppress_print_error_on() {
  for ds in "${DS[@]}"
  do
    header_file=$(_title_case_to_snake_case "${ds}")
    sed -i~ 's#^\#define SUPPRESS_PRINT_ERROR false#\#define SUPPRESS_PRINT_ERROR true#' ./main/"${ds}"/main/include/"${header_file}".h
  done
  for helper in "${HELPERS[@]}"
  do
    header_file=$(_title_case_to_snake_case "${helper}")
    sed -i~ 's#^\#define SUPPRESS_PRINT_ERROR false#\#define SUPPRESS_PRINT_ERROR true#' ./resources/helpers/"${helper}"/main/include/"${header_file}".h
  done
}

function set_suppress_print_error_off() {
  for ds in "${DS[@]}"
  do
    header_file=$(_title_case_to_snake_case "${ds}")
    sed -i~ 's#^\#define SUPPRESS_PRINT_ERROR true#\#define SUPPRESS_PRINT_ERROR false#' ./"${ds}"/main/include/"${header_file}".h
  done
  for helper in "${HELPERS[@]}"
  do
    header_file=$(_title_case_to_snake_case "${helper}")
    sed -i~ 's#^\#define SUPPRESS_PRINT_ERROR false#\#define SUPPRESS_PRINT_ERROR true#' ../resources/helpers/"${helper}"/main/include/"${header_file}".h
  done
}

function formatted_name() {
  # shellcheck disable=SC2001
  formatted="$(echo "${1}" | sed 's/\([A-Z]\)/ \1/g')"
  echo "$formatted"
}

function run_HELPERS_test_suite() {
  cd ./resources/helpers/ || exit 1
  for helper in "${HELPERS[@]}"
  do
    start_for_helper=$(date +%s)
    formatted_helper=$(formatted_name "${helper}")
    echo "Executing test for$formatted_helper..."
    cd ./"${helper}" || exit 1
    make run_tests -s || exit 1
    make run_tests -s | grep -o -P '\d+ Test(?:|s) (?:\d+ Failures)' >> ../../scripts/test/tests_result.txt
    cd ..
    end_for_helper=$(date +%s)
    echo "${YELLOW}Test executed for$formatted_helper in $(( end_for_helper - start_for_helper ))s..."
  done
}

function run_DS_test_suite() {
  cd ../../main/ || exit 1
  for ds in "${DS[@]}"
  do
    start_for_ds=$(date +%s)
    formatted_ds=$(formatted_name "${ds}")
    echo "Executing test for$formatted_ds..."
    cd ./"${ds}" || exit 1
    make run_tests -s || exit 1
    make run_tests -s | grep -o -P '\d+ Test(?:|s) (?:\d+ Failures)' >> ../../resources/scripts/test/tests_result.txt
    cd ..
    end_for_ds=$(date +%s)
    echo "${YELLOW}Test executed for$formatted_ds in $(( end_for_ds - start_for_ds ))s..."
  done
}

clear
set_suppress_print_error_on
run_HELPERS_test_suite
run_DS_test_suite
set_suppress_print_error_off
_parse_test_result
executed=$(_get_executed_tests)
failed=$(_get_failed_tests)
passed=$(( $executed - $failed))

end=$(date +%s)
echo "${executed} Tests executed in $(( end - start ))s
${passed} Pass
${failed} Fail"
rm -rf ../resources/scripts/test/tests_result.txt

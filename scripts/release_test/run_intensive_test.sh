#!/bin/bash

##############################################################################
# Bash script that builds and tests Metall with many compile time configurations
# This test would take a few hours at least
#
# 1. Set environmental variables for build, if needed
# 2. Run this script from the root directory of Metall
# cd metall # Metall root directory
# bash ./scripts/release_test/run_intensive_test.sh
##############################################################################

#######################################
# main function
#
# Used environmental variables:
#   METALL_BUILD_DIR (option)
#   METALL_TEST_DIR (option)
#   METALL_BUILD_TYPES (option)
#     E.g. METALL_BUILD_TYPES="Debug;Release;RelWithDebInfo"
#   METALL_CMAKE_ADDITIONAL_OPTIONS (option)
#     E.g. METALL_CMAKE_ADDITIONAL_OPTIONS="-DBOOST_INCLUDE_ROOT=/path/to/boost"
# Outputs: STDOUT and STDERR
#######################################
main() {
  readonly METALL_ROOT_DIR=${PWD}
  source ${METALL_ROOT_DIR}/scripts/test_kernel.sh
  source ${METALL_ROOT_DIR}/scripts/test_utility.sh

  echo "Build and test on ${HOSTNAME}"
  show_system_info

  if [[ -z "${METALL_BUILD_DIR}" ]]; then
    readonly METALL_BUILD_DIR="${METALL_ROOT_DIR}/build_${RANDOM}"
  fi

  setup_test_dir
  export METALL_TEST_DIR

  # Build documents
  build_docs

  for BUILD_TYPE in Debug RelWithDebInfo Release; do
    for DISABLE_FREE_FILE_SPACE in true false; do
      for DISABLE_SMALL_OBJECT_CACHE in true false; do
        for FREE_SMALL_OBJECT_SIZE_HINT in 0 8 4096 65536; do
          for USE_ANONYMOUS_NEW_MAP in true false; do

            DEFS="METALL_VERBOSE_SYSTEM_SUPPORT_WARNING;"

            if [[ "${DISABLE_FREE_FILE_SPACE}" == "true" ]]; then
              DEFS="${DEFS}METALL_DISABLE_FREE_FILE_SPACE;"
            fi

            if [[ "${DISABLE_SMALL_OBJECT_CACHE}" == "true" ]]; then
              DEFS="${DEFS}METALL_DISABLE_SMALL_OBJECT_CACHE;"
            fi

            if [ "${FREE_SMALL_OBJECT_SIZE_HINT}" -gt 0 ]; then
              DEFS="${DEFS}METALL_FREE_SMALL_OBJECT_SIZE_HINT=${FREE_SMALL_OBJECT_SIZE_HINT};"
            fi

            if [[ "${USE_ANONYMOUS_NEW_MAP}" == "true" ]]; then
              DEFS="${DEFS}METALL_USE_ANONYMOUS_NEW_MAP;"
            fi

            run_build_and_test_kernel \
              -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
              -DBUILD_BENCH=ON \
              -DBUILD_TEST=ON \
              -DRUN_LARGE_SCALE_TEST=ON \
              -DBUILD_DOC=OFF \
              -DBUILD_C=ON \
              -DBUILD_UTILITY=ON \
              -DBUILD_EXAMPLE=ON \
              -DRUN_BUILD_AND_TEST_WITH_CI=OFF \
              -DBUILD_VERIFICATION=OFF \
              -DCOMPILER_DEFS="${DEFS}" \
              " ${METALL_CMAKE_ADDITIONAL_OPTIONS} "
            done
        done
      done
    done
  done
}

main "$@"

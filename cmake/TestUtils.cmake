#################################################
macro (ign_build_tests)
  # Find the Python interpreter for running the
  # check_test_ran.py script
  find_package(PythonInterp QUIET)

  # Build all the tests
  foreach(GTEST_SOURCE_file ${ARGN})
    string(REGEX REPLACE ".cc" "" BINARY_NAME ${GTEST_SOURCE_file})
    set(BINARY_NAME ${TEST_TYPE}_${BINARY_NAME})
    if(USE_LOW_MEMORY_TESTS)
      add_definitions(-DUSE_LOW_MEMORY_TESTS=1)
    endif(USE_LOW_MEMORY_TESTS)

    if (BINARY_NAME STREQUAL "UNIT_ColladaExporter_TEST")
	    list (APPEND GTEST_SOURCE_file ${CMAKE_SOURCE_DIR}/src/tinyxml2/ignition/tinyxml2.cpp)
    endif()

    add_executable(${BINARY_NAME} ${GTEST_SOURCE_file})

    add_dependencies(${BINARY_NAME}
      ${PROJECT_LIBRARY_TARGET_NAME}
      gtest gtest_main
      )

    if (UNIX)
      target_link_libraries(${BINARY_NAME}
         libgtest_main.a
         libgtest.a
         pthread
         ${PROJECT_NAME_LOWER}
	 ${IGNITION-MATH_LIBRARIES})
    elseif(WIN32)
      target_link_libraries(${BINARY_NAME}
         gtest.lib
         gtest_main.lib
         ${PROJECT_NAME_LOWER}.lib
         ${IGNITION-MATH_LIBRARIES})

      # Copy in ignition-math library
      add_custom_command(TARGET ${BINARY_NAME}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${IGNITION-MATH_LIBRARY_DIRS}/${IGNITION-MATH_LIBRARIES}.dll"
        $<TARGET_FILE_DIR:${BINARY_NAME}> VERBATIM)

      # Copy in ignition-common library
      add_custom_command(TARGET ${BINARY_NAME}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_BINARY_DIR}/src/${PROJECT_NAME}.dll"
        $<TARGET_FILE_DIR:${BINARY_NAME}> VERBATIM)
    else()
       message(FATAL_ERROR "Unsupported platform")
    endif()

    add_test(${BINARY_NAME} ${CMAKE_CURRENT_BINARY_DIR}/${BINARY_NAME}
	--gtest_output=xml:${CMAKE_BINARY_DIR}/test_results/${BINARY_NAME}.xml)

    set_tests_properties(${BINARY_NAME} PROPERTIES TIMEOUT 240)

    if(PYTHONINTERP_FOUND)
      # Check that the test produced a result and create a failure if it didn't.
      # Guards against crashed and timed out tests.
      add_test(check_${BINARY_NAME} ${PYTHON_EXECUTABLE} ${PROJECT_SOURCE_DIR}/tools/check_test_ran.py
        ${CMAKE_BINARY_DIR}/test_results/${BINARY_NAME}.xml)
    endif()
  endforeach()
endmacro()


#################################################
# ign_find_package(<PACKAGE_NAME> [REQUIRED] [EXACT] [QUIET] [PRIVATE]
#                  [VERSION <ver>]
#                  [EXTRA_ARGS <args>]
#                  [PRETTY <name>]
#                  [PURPOSE <"explanation for this dependency">])
#
# This is a wrapper for the standard cmake find_package which behaves according
# to the conventions of the ignition library. In particular, we do not quit
# immediately when a required package is missing. Instead, we check all
# dependencies and provide an overview of what is missing at the end of the
# configuration process. Descriptions of the function arguments are as follows:
#
# <PACKAGE_NAME>: The name of the package as it would normally be passed to
#                 find_package(~)
#
# [REQUIRED]: Optional. If provided, this will trigger an ignition build_error.
#             If not provided, this will trigger an ignition build_warning.
#
# [EXACT]: Optional. This will pass on the EXACT option to find_package(~) and
#          also add it to the call to find_dependency(~) in the
#          <project>-config.cmake file.
#
# [QUIET]: Optional. If provided, it will be passed forward to cmake's
#          find_package(~) command. This function will still print its normal
#          output.
#
# [PRIVATE]: Not recommended. This package will not be added to the list of
#            package dependencies that must be found by
#            <PROJECT_NAME>-config.cmake. Only use this if you are certain of
#            what you are doing.
#
# [VERSION]: Optional. Follow this argument with the major[.minor[.patch[.tweak]]]
#            version that you need for this package.
#
# [EXTRA_ARGS]: Optional. Additional args to pass forward to find_package(~)
#
# [PRETTY]: Optional. If provided, the string that follows will replace
#           <PACKAGE_NAME> when printing messages, warnings, or errors to the
#           terminal.
#
# [PURPOSE]: Optional. If provided, the string that follows will be appended to
#            the build_warning or build_error that this function produces when
#            the package could not be found.
#
macro(ign_find_package PACKAGE_NAME)

  #------------------------------------
  # Define the expected arguments
  set(options REQUIRED QUIET PRIVATE EXACT)
  set(oneValueArgs VERSION PRETTY PURPOSE EXTRA_ARGS)
  set(multiValueArgs) # We are not using multiValueArgs yet

  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_find_package "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  #------------------------------------
  # Construct the arguments to pass to find_package
  if(ign_find_package_VERSION)
    list(APPEND ${PACKAGE_NAME}_find_package_args ${ign_find_package_VERSION})
  endif()

  if(ign_find_package_QUIET)
    list(APPEND ${PACKAGE_NAME}_find_package_args QUIET)
  endif()

  if(ign_find_package_EXACT)
    list(APPEND ${PACKAGE_NAME}_find_package_args EXACT)
  endif()

  if(ign_find_package_EXTRA_ARGS)
    list(APPEND ${PACKAGE_NAME}_find_package_args ${ign_find_package_EXTRA_ARGS})
  endif()

  #------------------------------------
  # Figure out which name to print
  if(ign_find_package_PRETTY)
    set(${PACKAGE_NAME}_pretty ${ign_find_package_PRETTY})
  else()
    set(${PACKAGE_NAME}_pretty ${PACKAGE_NAME})
  endif()


  #------------------------------------
  # Call find_package with the provided arguments
  find_package(${PACKAGE_NAME} ${${PACKAGE_NAME}_find_package_args})
  if(${PACKAGE_NAME}_FOUND)
    message(STATUS "Looking for ${${PACKAGE_NAME}_pretty} - found\n")
  else()
    message(STATUS "Looking for ${${PACKAGE_NAME}_pretty} - not found\n")

    #------------------------------------
    # Construct the warning/error message to produce
    set(${PACKAGE_NAME}_msg "Missing: ${${PACKAGE_NAME}_pretty}")
    if(DEFINED ign_find_package_PURPOSE)
      set(${PACKAGE_NAME}_msg "${${PACKAGE_NAME}_msg} - ${ign_find_package_PURPOSE}")
    endif()

    #------------------------------------
    # Produce an error if the package is required, or a warning if it is not
    if(ign_find_package_REQUIRED)
      ign_build_error(${${PACKAGE_NAME}_msg})
    else()
      ign_build_warning(${${PACKAGE_NAME}_msg})
    endif()
  endif()


  #------------------------------------
  # Add this package to the list of dependencies that will be inserted into the
  # find-config file, unless the invoker specifies that it should not be added
  if(NOT ign_find_package_PRIVATE)

    # Set up the arguments we want to pass to the find_dependency invokation for
    # our ignition project. We always need to pass the name of the dependency.
    set(${PACKAGE_NAME}_dependency_args ${PACKAGE_NAME})

    # If a version is provided here, we should pass that as well.
    if(ign_find_package_VERSION)
      ign_string_append(${PACKAGE_NAME}_dependency_args ${ign_find_package_VERSION})
    endif()

    # If we have specified the exact version, we should provide that as well.
    if(ign_find_package_EXACT)
      ign_string_append(${PACKAGE_NAME}_dependency_args EXACT)
    endif()

    list(APPEND PROJECT_CONFIG_DEPENDENCIES "${${PACKAGE_NAME}_dependency_args}")

  endif()

endmacro()

#################################################
# Macro to turn a list into a string (why doesn't CMake have this built-in?)
macro(ign_list_to_string _string _list)
    set(${_string})
    foreach(_item ${_list})
      set(${_string} "${${_string}} ${_item}")
    endforeach(_item)
    #string(STRIP ${${_string}} ${_string})
endmacro()

#################################################
# Macro to append a value to a string
macro(ign_string_append output_var val)

  set(${output_var} "${${output_var}} ${val}")

endmacro()

#################################################
# ign_get_sources_and_unittests(<lib_srcs> <tests>)
#
# From the current directory, grab all the files ending in "*.cc" and sort them
# into library source files <lib_srcs> and unittest source files <tests>. Remove
# their paths to make them suitable for passing into ign_add_[library/tests].
function(ign_get_libsources_and_unittests lib_sources_var tests_var)

  # GLOB all the source files
  file(GLOB source_files "*.cc")
  list(SORT source_files)

  # GLOB all the unit tests
  file(GLOB test_files "*_TEST.cc")
  list(SORT test_files)

  # Initialize these lists
  set(tests)
  set(sources)

  # Remove the unit tests from the list of source files
  foreach(test_file ${test_files})

    list(REMOVE_ITEM source_files ${test_file})

    # Remove the path from the unit test and append to the list of tests.
    get_filename_component(test ${test_file} NAME)
    list(APPEND tests ${test})

  endforeach()

  foreach(source_file ${source_files})

    # Remove the path from the library source file and append it to the list of
    # library source files.
    get_filename_component(source ${source_file} NAME)
    list(APPEND sources ${source})

  endforeach()

  # Return the lists that have been created.
  set(${lib_sources_var} ${sources} PARENT_SCOPE)
  set(${tests_var} ${tests} PARENT_SCOPE)

endfunction()

#################################################
# ign_get_sources(<sources>)
#
# From the current directory, grab all the source files and place them into
# <sources>. Remove their paths to make them suitable for passing into
# ign_add_[library/tests].
function(ign_get_sources sources_var)

  # GLOB all the source files
  file(GLOB source_files "*.cc")
  list(SORT source_files)

  # Initialize this list
  set(sources)

  foreach(source_file ${source_files})

    # Remove the path from the source file and append it the list of soures
    get_filename_component(source ${source_file} NAME)
    list(APPEND sources ${source})

  endforeach()

  # Return the list that has been created
  set(${sources_var} ${sources} PARENT_SCOPE)

endfunction()

#################################################
# ign_install_all_headers(
#   [ADDITIONAL_DIRS <dirs>]
#   [EXCLUDE <excluded_headers>])
#
# From the current directory, install all header files, including files from the
# "detail" subdirectory. You can optionally specify additional directories
# (besides detail) to also install. You may also specify header files to
# exclude from the installation. This will accept all files ending in *.h and
# *.hh. You may append an additional suffix (like .old or .backup) to prevent
# a file from being included here.
#
# This will also run configure_file on ign_auto_headers.hh.in and config.hh.in
# and install both of them.
function(ign_install_all_headers)

  #------------------------------------
  # Define the expected arguments
  set(options) # We are not using options yet
  set(oneValueArgs) # We are not using oneValueArgs yet
  set(multiValueArgs ADDITIONAL_DIRS EXCLUDE)

  #------------------------------------
  # Parse the arguments
  cmake_parse_arguments(ign_install_all_headers "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  #------------------------------------
  # Build list of directories
  set(dir_list "." "detail" ${ign_install_all_headers_ADDITIONAL_DIRS})

  #------------------------------------
  # Grab the excluded files
  set(excluded ${ign_install_all_headers_EXCLUDE})

  #------------------------------------
  # Initialize the string of all headers
  set(ign_headers)

  #------------------------------------
  # Install all the non-excluded headers
  foreach(dir ${dir_list})

    # GLOB all the header files in dir
    file(GLOB header_files "${dir}/*.h" "${dir}/*.hh")
    list(SORT header_files)

    # Replace full paths with relative paths
    set(headers)
    foreach(header_file ${header_files})

      get_filename_component(header ${header_file} NAME)
      if("." STREQUAL ${dir})
        list(APPEND headers ${header})
      else()
        list(APPEND headers ${dir}/${header})
      endif()

    endforeach()

    # Remove the excluded headers
    foreach(exclude ${excluded})
      list(REMOVE_ITEM headers ${exclude})
    endforeach()

    # Add each header, prefixed by its directory, to the auto headers variable
    foreach(header ${headers})
      set(ign_headers "${ign_headers}#include <ignition/${IGN_DESIGNATION}/${header}>\n")
    endforeach()

    if("." STREQUAL ${dir})
      set(destination "${IGN_INCLUDE_INSTALL_DIR_FULL}/ignition/${IGN_DESINATION}")
    else()
      set(destination "${IGN_INCLUDE_INSTALL_DIR_FULL}/ignition/${IGN_DESINATION}/${dir}")
    endif()

    install(
      FILES ${headers}
      DESTINATION ${destination}
      COMPONENT headers)

  endforeach()

  # Define the install directory for the meta headers
  set(meta_header_install_dir ${IGN_INCLUDE_INSTALL_DIR_FULL}/ignition/${IGN_DESIGNATION})

  # Define the input/output of the configuration for the "master" header
  set(master_header_in ${IGNITION_CMAKE_DIR}/ign_auto_headers.hh.in)
  set(master_header_out ${CMAKE_CURRENT_BINARY_DIR}/${IGN_DESIGNATION}.hh)

  # Generate the "master" header that includes all of the headers
  configure_file(${master_header_in} ${master_header_out})

  # Install the "master" header
  install(
    FILES ${master_header_out}
    DESTINATION ${meta_header_install_dir}
    COMPONENT headers)

  # Define the input/output of the configuration for the "config" header
  set(config_header_in ${CMAKE_CURRENT_SOURCE_DIR}/config.hh.in)
  set(config_header_out ${CMAKE_CURRENT_BINARY_DIR}/config.hh)

  # Generate the "config" header that describes our project configuration
  configure_file(${config_header_in} ${config_header_out})

  # Install the "config" header
  install(
    FILES ${config_header_out}
    DESTINATION ${meta_header_install_dir}
    COMPONENT headers)

endfunction()


#################################################
# ign_build_error macro
macro(ign_build_error)
  foreach(str ${ARGN})
    set(msg "\t${str}")
    list(APPEND build_errors ${msg})
  endforeach()
endmacro(ign_build_error)

#################################################
# ign_build_warning macro
macro(ign_build_warning)
  foreach(str ${ARGN})
    set(msg "\t${str}" )
    list(APPEND build_warnings ${msg})
  endforeach(str ${ARGN})
endmacro(ign_build_warning)

#################################################
macro(ign_add_library _name)

  set(LIBS_DESTINATION ${PROJECT_BINARY_DIR}/src)
  set_source_files_properties(${ARGN} PROPERTIES COMPILE_DEFINITIONS "BUILDING_DLL")
  add_library(${_name} SHARED ${ARGN})

endmacro()

#################################################
macro(ign_add_static_library _name)
  add_library(${_name} STATIC ${ARGN})
  target_link_libraries(${_name} ${general_libraries})
endmacro()

#################################################
macro(ign_add_executable _name)
  add_executable(${_name} ${ARGN})
  target_link_libraries(${_name} ${general_libraries})
endmacro()

#################################################
# ign_target_public_include_directories(<target> [include_targets])
#
# Add the INTERFACE_INCLUDE_DIRECTORIES of [include_targets] to the public
# INCLUDE_DIRECTORIES of <target>. This allows us to propagate the include
# directories of <target> along to any other libraries that depend on it.
#
# You MUST pass in targets to include, not directory names. We must not use
# explicit directory names here if we want our package to be relocatable.
function(ign_target_interface_include_directories name)

  foreach(include_target ${ARGN})
    target_include_directories(
      ${name} PUBLIC
      $<TARGET_PROPERTY:${include_target},INTERFACE_INCLUDE_DIRECTORIES>)
  endforeach()

endfunction()

#################################################
macro(ign_install_includes _subdir)
  install(FILES ${ARGN}
    DESTINATION ${IGN_INCLUDE_INSTALL_DIR}/${_subdir} COMPONENT headers)
endmacro()

#################################################
macro(ign_install_library)

  if(${ARGC} GREATER 0)
    message(WARNING "Warning to the developer: ign_install_library no longer "
                    "accepts any arguments. Please remove them from your call.")
  endif()

  set_target_properties(
    ${PROJECT_LIBRARY_TARGET_NAME}
    PROPERTIES
      SOVERSION ${PROJECT_VERSION_MAJOR}
      VERSION ${PROJECT_VERSION_FULL})

  install(
    TARGETS ${PROJECT_LIBRARY_TARGET_NAME}
    EXPORT ${PROJECT_EXPORT_NAME}
    LIBRARY
      DESTINATION ${IGN_LIB_INSTALL_DIR}
      COMPONENT shlib)

endmacro()

#################################################
macro(ign_install_executable _name )
  set_target_properties(${_name} PROPERTIES VERSION ${PROJECT_VERSION_FULL})
  install (TARGETS ${_name} DESTINATION ${IGN_BIN_INSTALL_DIR})
  manpage(${_name} 1)
endmacro()



# This should be migrated to more fine control solution based on set_property APPEND
# directories. It's present on cmake 2.8.8 while precise version is 2.8.7
link_directories(${PROJECT_BINARY_DIR}/test)
include_directories("${PROJECT_SOURCE_DIR}/test/gtest/include")

#################################################
# Enable tests compilation by default
if (NOT DEFINED ENABLE_TESTS_COMPILATION)
  set (ENABLE_TESTS_COMPILATION True)
endif()

#################################################
# Macro to setup supported compiler warnings
# Based on work of Florent Lamiraux, Thomas Moulard, JRL, CNRS/AIST.
include(CheckCXXCompilerFlag)

macro(ign_filter_valid_compiler_options var)
  # Store the current setting for CMAKE_REQUIRED_QUIET
  set(original_cmake_required_quiet ${CMAKE_REQUIRED_QUIET})

  # Make these tests quiet so they don't pollute the cmake output
  set(CMAKE_REQUIRED_QUIET true)

  foreach(flag ${ARGN})
    CHECK_CXX_COMPILER_FLAG(${flag} result${flag})
    if(result${flag})
      set(${var} "${${var}} ${flag}")
    endif()
  endforeach()

  # Restore the old setting for CMAKE_REQUIRED_QUIET
  set(CMAKE_REQUIRED_QUIET ${original_cmake_required_quiet})
endmacro()

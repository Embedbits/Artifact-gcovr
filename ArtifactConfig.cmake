#------------------------------------------------------------------------------#
# Returns artifact version.
#
# The name of function must consist of folder name (gcovr) and postfix
# (_GetArtifactVersion). Otherwise the buildprocess will fail.
#
# Asks the executable resolved by gcovr_ArtifactInit() (GCOVR_EXECUTABLE), falls
# back to "gcovr" from PATH if the artifact was not initialized.
#
# ARTIFACT_VERSION [out]: Version of artifact in format X.Y.Z
#------------------------------------------------------------------------------#
function(gcovr_GetArtifactVersion RET_VERSION)

    if(GCOVR_EXECUTABLE)
        set(GCOVR_COMMAND "${GCOVR_EXECUTABLE}")
    else()
        set(GCOVR_COMMAND gcovr)
    endif()

    execute_process(COMMAND "${GCOVR_COMMAND}" --version
                    OUTPUT_VARIABLE ARTIFACT_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    # "gcovr 8.6" - the artifact version is completed to X.Y.Z (8.6.0)
    string(REGEX MATCH "[0-9]+\\.[0-9]+(\\.[0-9]+)?" VERSION "${ARTIFACT_VERSION}")

    if(VERSION MATCHES "^[0-9]+\\.[0-9]+$")
        set(VERSION "${VERSION}.0")
    endif()

    set(${RET_VERSION} "${VERSION}" PARENT_SCOPE)

endfunction()


#------------------------------------------------------------------------------#
# Initialize artifact for build.
#
# The name of function must consist of folder name (gcovr) and postfix
# (_ArtifactInit). Otherwise the buildprocess will fail.
#
# Binary part is gcovr frozen to a standalone application (folder gcovr/ with the
# executable and its own libraries, built by Gcovr_Build.sh from the artifact
# "python"): it needs no Python, no package and no library of the system except
# the C library. Per platform:
#   Win       - gcovr.exe
#   Unix      - gcovr (Linux x86_64, glibc)
#
# gcovr only evaluates the data of gcov, the gcov of the compiler that built the
# code under test is not part of it (gcc: next to the compiler, see the
# artifacts gcc and gcc-arm-none-eabi).
#
# NOTE: set(ENV{PATH} ...) below only affects the running CMake configure
# process. It does NOT reach commands added via add_custom_target/
# add_custom_command, since those run later as a separate build-tool
# process (ninja/make) that does not inherit configure-time ENV changes.
# For that reason this function also exports the resolved absolute
# executable path as the CACHE variable GCOVR_EXECUTABLE - use that (not a
# bare "gcovr") inside any COMMAND that runs at build time, e.g.:
#
#   add_custom_target(Coverage
#       COMMAND ${GCOVR_EXECUTABLE} --root ${CMAKE_SOURCE_DIR} --gcov-executable ${GCOV_EXECUTABLE}
#               --cobertura ${CMAKE_BINARY_DIR}/Cobertura.xml ${CMAKE_BINARY_DIR}
#       USES_TERMINAL)
#
# ARTIFACT_BIN_PATH_ARG [in]: Path to the binary part of artifact
#------------------------------------------------------------------------------#
function(gcovr_ArtifactInit ARTIFACT_BIN_PATH_ARG)

    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        set(GCOVR_FILE_NAME "gcovr.exe")
        set(PATH_SEPARATOR ";")
    else()
        set(GCOVR_FILE_NAME "gcovr")
        set(PATH_SEPARATOR ":")
    endif()

    file(GLOB_RECURSE GCOVR_FILES "${ARTIFACT_BIN_PATH_ARG}/*/${GCOVR_FILE_NAME}" "${ARTIFACT_BIN_PATH_ARG}/${GCOVR_FILE_NAME}")

    # The executable of the application, not a file named gcovr in the libraries
    # of the application (_internal/)
    list(FILTER GCOVR_FILES EXCLUDE REGEX "/_internal/")

    if(NOT GCOVR_FILES)
        message(FATAL_ERROR "File ${GCOVR_FILE_NAME} not found in ${ARTIFACT_BIN_PATH_ARG}.")
    endif()

    list(GET GCOVR_FILES 0 RESOLVED_EXECUTABLE)
    get_filename_component(CONFIG_DIR "${RESOLVED_EXECUTABLE}" DIRECTORY)

    # The archive of the artifact may be extracted without the execute permission
    if(NOT ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        file(CHMOD "${RESOLVED_EXECUTABLE}"
             PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    endif()

    message(STATUS "File ${GCOVR_FILE_NAME} found in: ${CONFIG_DIR}")

    set(ENV{PATH} "${CONFIG_DIR}${PATH_SEPARATOR}$ENV{PATH}")

    set(GCOVR_EXECUTABLE "${RESOLVED_EXECUTABLE}" CACHE FILEPATH "Absolute path to the resolved gcovr executable" FORCE)

    message(DEBUG "gcovr was added to PATH from: ${CONFIG_DIR}")
    message(DEBUG "GCOVR_EXECUTABLE set to: ${GCOVR_EXECUTABLE}")

endfunction()

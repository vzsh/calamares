# === This file is part of Calamares - <https://github.com/calamares> ===
#
#   Calamares is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Calamares is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Calamares. If not, see <http://www.gnu.org/licenses/>.
#
#   SPDX-License-Identifier: GPL-3.0-or-later
#   License-Filename: LICENSE
#
###
#
# This file has not yet been documented for use outside of Calamares itself.

include( CMakeParseArguments )

# Internal macro for adding the C++ / Qt translations to the
# build and install tree. Should be called only once, from
# src/calamares/CMakeLists.txt.
macro(add_calamares_translations language)
    list( APPEND CALAMARES_LANGUAGES ${ARGV} )

    set( calamares_i18n_qrc_content "" )

    # calamares and qt language files
    foreach( lang ${CALAMARES_LANGUAGES} )
        foreach( tlsource "calamares_${lang}" "tz_${lang}" )
            if( EXISTS "${CMAKE_SOURCE_DIR}/lang/${tlsource}.ts" )
                set( calamares_i18n_qrc_content "${calamares_i18n_qrc_content}<file>${tlsource}.qm</file>\n" )
                list( APPEND TS_FILES "${CMAKE_SOURCE_DIR}/lang/${tlsource}.ts" )
            endif()
        endforeach()
    endforeach()

    set( trans_file calamares_i18n )
    set( trans_infile ${CMAKE_CURRENT_BINARY_DIR}/${trans_file}.qrc )
    set( trans_outfile ${CMAKE_CURRENT_BINARY_DIR}/qrc_${trans_file}.cxx )

    configure_file( ${CMAKE_SOURCE_DIR}/lang/calamares_i18n.qrc.in ${trans_infile} @ONLY )

    qt5_add_translation(QM_FILES ${TS_FILES})

    # Run the resource compiler (rcc_options should already be set)
    add_custom_command(
        OUTPUT ${trans_outfile}
        COMMAND "${Qt5Core_RCC_EXECUTABLE}"
        ARGS ${rcc_options} --format-version 1 -name ${trans_file} -o ${trans_outfile} ${trans_infile}
        MAIN_DEPENDENCY ${trans_infile}
        DEPENDS ${QM_FILES}
    )
endmacro()

# Internal macro for Python translations
#
# Translations of the Python modules that don't have their own
# lang/ subdirectories -- these are collected in top-level
# lang/python/<lang>/LC_MESSAGES/python.mo
macro(add_calamares_python_translations language)
    set( CALAMARES_LANGUAGES "" )
    list( APPEND CALAMARES_LANGUAGES ${ARGV} )

    install_calamares_gettext_translations( python
        SOURCE_DIR ${CMAKE_SOURCE_DIR}/lang/python
        FILENAME python.mo
        RENAME calamares-python.mo
    )
endmacro()

# Installs a directory containing language-code-labeled subdirectories with
# gettext data into the appropriate system directory. Allows renaming the
# .mo files during install to avoid namespace clashes.
#
# install_calamares_gettext_translations(
#   NAME <name of module, for human use>
#   SOURCE_DIR path/to/lang
#   FILENAME <name of file.mo>
#   [RENAME <new-name of.mo>]
# )
#
# For all of the (global) translation languages enabled for Calamares,
# try installing $SOURCE_DIR/$lang/LC_MESSAGES/<filename>.mo into the
# system gettext data directory (e.g. share/locale/), possibly renaming
# filename.mo to renamed.mo in the process.
function( install_calamares_gettext_translations )
    # parse arguments ( name needs to be saved before passing ARGN into the macro )
    set( NAME ${ARGV0} )
    set( oneValueArgs NAME SOURCE_DIR FILENAME RENAME )
    cmake_parse_arguments( TRANSLATION "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    if( NOT TRANSLATION_NAME )
        set( TRANSLATION_NAME ${NAME} )
    endif()
    if( NOT TRANSLATION_FILENAME )
        set( TRANSLATION_FILENAME "${TRANSLATION_NAME}.mo" )
    endif()
    if( NOT TRANSLATION_RENAME )
        set( TRANSLATION_RENAME "${TRANSLATION_FILENAME}" )
    endif()

    message(STATUS "Installing gettext translations for ${TRANSLATION_NAME}")
    message(STATUS "  Installing ${TRANSLATION_FILENAME} from ${TRANSLATION_SOURCE_DIR}")

    set( TRANSLATION_NAME "${NAME}" )
    set( INSTALLED_TRANSLATIONS "" )
    foreach( lang ${CALAMARES_TRANSLATION_LANGUAGES} )  # Global
        set( lang_mo "${TRANSLATION_SOURCE_DIR}/${lang}/LC_MESSAGES/${TRANSLATION_FILENAME}" )
        if( lang STREQUAL "en" )
            message( STATUS "  Skipping ${TRANSLATION_NAME} translations for en_US" )
        else( EXISTS ${lang_mo} )
            list( APPEND INSTALLED_LANGUAGES "${lang}" )
            install(
                FILES ${lang_mo}
                DESTINATION ${CMAKE_INSTALL_LOCALEDIR}/${lang}/LC_MESSAGES/
                RENAME ${TRANSLATION_RENAME}
            )
            # TODO: make translations available in build dir too, for
            #       translation when running calamares -d from builddir.
            set(_build_lc ${CMAKE_BINARY_DIR}/lang/${lang}/LC_MESSAGES/)
            file(COPY ${lang_mo} DESTINATION ${_build_lc})
            if (NOT TRANSLATION_FILENAME STREQUAL TRANSLATION_RENAME)
                file(RENAME ${_build_lc}${TRANSLATION_FILENAME} ${_build_lc}${TRANSLATION_RENAME})
            endif()

        endif()
    endforeach()
endfunction()

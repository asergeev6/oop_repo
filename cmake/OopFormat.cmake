# Цели форматирования кода по правилам из .clang-format:
#   cmake --build --preset dev --target format        - переформатировать файлы на месте
#   cmake --build --preset dev --target format-check  - проверить, ничего не меняя
#
# format-check возвращает ненулевой код, если файл отформатирован не по правилам,
# и печатает нужные изменения. Именно эта цель гоняется в CI.

find_program(OOP_CLANG_FORMAT NAMES clang-format)

if(NOT OOP_CLANG_FORMAT)
    message(STATUS "OOP: clang-format не найден, цели format и format-check недоступны")
    return()
endif()

# Собираем исходники всех задач. CONFIGURE_DEPENDS заставляет CMake перечитать
# список при появлении новых файлов.
file(GLOB_RECURSE OOP_FORMAT_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/tasks/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tasks/*.h
)

if(NOT OOP_FORMAT_SOURCES)
    return()
endif()

add_custom_target(format
    COMMAND ${OOP_CLANG_FORMAT} -i --style=file ${OOP_FORMAT_SOURCES}
    COMMENT "Форматирование исходников задач по .clang-format"
    VERBATIM
)

add_custom_target(format-check
    COMMAND ${OOP_CLANG_FORMAT} --dry-run --Werror --style=file ${OOP_FORMAT_SOURCES}
    COMMENT "Проверка форматирования (изменений не вносит)"
    VERBATIM
)

message(STATUS "OOP: clang-format найден (${OOP_CLANG_FORMAT}), цели format и format-check доступны")

# Цель tidy-fix: исправить механические замечания clang-tidy автоматически.
#
#   cmake --build --preset dev --target tidy-fix
#
# Большая часть замечаний линтера чинится подстановкой без участия человека:
# заголовок <stdio.h> на <cstdio>, NULL на nullptr, неинициализированная переменная,
# неявное приведение к bool. Тратить на это своё время (или токены ассистента)
# незачем - для этого есть одна команда.
#
# Замечания, которые останутся после tidy-fix, - это те, где требуется решение:
# пропущенная ветка default в switch, сужающее преобразование типа, ошибка
# работы с памятью. Их и надо разбирать.

find_program(OOP_CLANG_TIDY_FIX NAMES clang-tidy)

if(NOT OOP_CLANG_TIDY_FIX)
    return()
endif()

file(GLOB_RECURSE OOP_TIDY_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/tasks/*.cpp
)

# Файлы замеров в обычную сборку не входят, значит их нет в compile_commands.json
# и clang-tidy не сможет их разобрать. Проверяются они пресетом bench.
list(FILTER OOP_TIDY_SOURCES EXCLUDE REGEX "_bench\\.cpp$")

if(NOT OOP_TIDY_SOURCES)
    return()
endif()

# На macOS системный компилятор знает путь к SDK неявно, и в compile_commands.json
# он не попадает. Отдельно запущенный clang-tidy без него не находит даже <string>.
# CMAKE_OSX_SYSROOT при системном компиляторе пуст, поэтому спрашиваем у xcrun.
set(OOP_TIDY_EXTRA "")
if(APPLE)
    set(OOP_TIDY_SDK "${CMAKE_OSX_SYSROOT}")
    if(NOT OOP_TIDY_SDK)
        execute_process(COMMAND xcrun --show-sdk-path
                        OUTPUT_VARIABLE OOP_TIDY_SDK
                        OUTPUT_STRIP_TRAILING_WHITESPACE
                        ERROR_QUIET)
    endif()
    if(OOP_TIDY_SDK)
        set(OOP_TIDY_EXTRA --extra-arg=-isysroot --extra-arg=${OOP_TIDY_SDK})
    endif()
endif()

# -p указывает каталог с compile_commands.json, он же каталог сборки.
add_custom_target(tidy-fix
    COMMAND ${OOP_CLANG_TIDY_FIX} -p ${CMAKE_BINARY_DIR} --fix --quiet
            ${OOP_TIDY_EXTRA} ${OOP_TIDY_SOURCES}
    COMMENT "Автоисправление механических замечаний clang-tidy"
    VERBATIM
)

# Все настройки проверок курса собраны здесь.
# Результат - "виртуальная" библиотека oop_flags, которую подключают все цели задач.
# Отдельная библиотека нужна для того, чтобы строгие флаги применялись только к вашему
# коду: GoogleTest собирается со своими настройками и его предупреждения вам не мешают.

add_library(oop_flags INTERFACE)

# ---------------------------------------------------------------------------
# Предупреждения компилятора
# ---------------------------------------------------------------------------
if(MSVC)
    target_compile_options(oop_flags INTERFACE
        /W4              # высокий уровень диагностики
        /permissive-     # строгое соответствие стандарту
        /utf-8           # исходники в UTF-8 (иначе русские комментарии ломают сборку)
        /Zc:__cplusplus  # корректное значение макроса __cplusplus
    )
    if(OOP_WERROR)
        target_compile_options(oop_flags INTERFACE /WX)
    endif()
else()
    target_compile_options(oop_flags INTERFACE
        -Wall -Wextra -Wpedantic
        -Wconversion         # неявная потеря данных: double -> int, int -> int16_t
        -Wsign-conversion    # отрицательный int превращается в огромный size_t
        -Wshadow             # локальная переменная закрывает поле класса
        -Wnon-virtual-dtor   # удаление наследника через указатель на базу без virtual ~
        -Woverloaded-virtual # метод наследника прячет виртуальный метод базы
    )
    if(OOP_WERROR)
        target_compile_options(oop_flags INTERFACE -Werror)
    endif()
endif()

# ---------------------------------------------------------------------------
# Санитайзеры
# Компилятор встраивает в программу дополнительные проверки. При ошибке программа
# падает с отчётом (файл, строка, стек) вместо того, чтобы "иногда работать".
# ---------------------------------------------------------------------------
if(OOP_SANITIZE)
    if(MSVC)
        # На MSVC есть только AddressSanitizer.
        # Он несовместим со штатными проверками /RTC1 и инкрементальной линковкой.
        string(REGEX REPLACE "/RTC[1csu]*" "" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
        set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}" PARENT_SCOPE)
        target_compile_options(oop_flags INTERFACE /fsanitize=address /Zi)
        target_link_options(oop_flags INTERFACE /INCREMENTAL:NO)
        message(STATUS "OOP: AddressSanitizer включён (UBSan на MSVC недоступен)")
    else()
        target_compile_options(oop_flags INTERFACE
            -fsanitize=address,undefined
            -fno-omit-frame-pointer
            -fno-sanitize-recover=all  # первая же ошибка - падение, а не строчка в логе
            -g -O1)
        target_link_options(oop_flags INTERFACE -fsanitize=address,undefined)
        message(STATUS "OOP: AddressSanitizer и UndefinedBehaviorSanitizer включены")
    endif()
endif()

# ---------------------------------------------------------------------------
# Покрытие кода тестами
# ---------------------------------------------------------------------------
if(OOP_COVERAGE)
    if(MSVC)
        message(WARNING
            "OOP_COVERAGE не поддерживается компилятором MSVC. "
            "Покрытие меряется на Linux/macOS или в GitHub Actions.")
    else()
        target_compile_options(oop_flags INTERFACE --coverage -O0 -g)
        target_link_options(oop_flags INTERFACE --coverage)
        message(STATUS "OOP: сбор покрытия включён")
    endif()
endif()

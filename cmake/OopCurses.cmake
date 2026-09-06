# Поддержка curses - библиотеки управления терминалом (курсор, цвета, ввод без Enter).
#
# На Linux и macOS используется системная ncurses, на Windows скачивается PDCurses.
# Библиотека НЕ обязательна: если её нет, цели с пометкой CURSES просто не собираются,
# а остальные задачи собираются как обычно. Так студент без ncurses не остаётся
# без всего проекта из-за одной задачи.
#
# Результат работы модуля - цель oop_curses, если библиотека доступна.

if(WIN32 OR MSVC)
    include(FetchContent)
    # Форк с поддержкой CMake: в основном репозитории PDCurses сборка на makefile,
    # и FetchContent с ним не работает. Коммит зафиксирован, чтобы сборка была
    # воспроизводимой.
    FetchContent_Declare(
        pdcurses
        GIT_REPOSITORY https://github.com/dsavenko/PDCurses.git
        GIT_TAG dfbac0fe5ef90a40a67d6b13cc7d9c69bf40a5f5
    )
    set(PDC_BUILD_SHARED OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(pdcurses)
    if(TARGET pdcurses)
        add_library(oop_curses INTERFACE)
        target_link_libraries(oop_curses INTERFACE pdcurses)
        set(OOP_HAVE_CURSES TRUE CACHE INTERNAL "")
        message(STATUS "OOP: терминальная графика через PDCurses")
    endif()
else()
    set(CURSES_NEED_NCURSES TRUE)
    find_package(Curses QUIET)
    if(Curses_FOUND)
        add_library(oop_curses INTERFACE)
        target_include_directories(oop_curses INTERFACE ${CURSES_INCLUDE_DIRS})
        target_link_libraries(oop_curses INTERFACE ${CURSES_LIBRARIES})
        set(OOP_HAVE_CURSES TRUE CACHE INTERNAL "")
        message(STATUS "OOP: терминальная графика через ncurses (${CURSES_LIBRARIES})")
    endif()
endif()

if(NOT OOP_HAVE_CURSES)
    message(STATUS
        "OOP: ncurses не найдена, задачи с терминальной графикой пропускаются. "
        "Установка: Ubuntu 'sudo apt install libncurses-dev', macOS 'brew install ncurses'. "
        "Остальные задачи собираются как обычно.")
endif()

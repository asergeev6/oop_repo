# Функция oop_task() описывает одну задачу курса.
#
# Использование в tasks/<имя>/CMakeLists.txt:
#
#   oop_task(
#     NAME    task1b            # обязательно: имя задачи, оно же имя программы
#     SOURCES word_count.cpp    # файлы реализации (без main.cpp и без тестов)
#     MAIN    main.cpp          # файл с функцией main (можно не указывать)
#     TESTS   word_count_test.cpp  # файлы тестов (можно не указывать)
#     BENCH   word_count_bench.cpp # замеры производительности (можно не указывать)
#     CURSES                    # задаче нужна терминальная графика (ncurses/PDCurses)
#   )
#
# Пометка CURSES относится только к программе (MAIN): библиотека кода и тесты
# от curses не зависят и собираются всегда. Если curses в системе нет,
# программа просто не собирается, а тесты и остальные задачи работают.
#
# Создаются цели:
#   <NAME>_lib   - код задачи (подключается и к программе, и к тестам)
#   <NAME>       - исполняемая программа, если задан MAIN
#   <NAME>_tests - тесты, если задан TESTS; каждый TEST(...) регистрируется в CTest
#   <NAME>_bench - замеры, если задан BENCH и включён пресет bench

function(oop_task)
    cmake_parse_arguments(T "CURSES" "NAME;MAIN" "SOURCES;TESTS;BENCH" ${ARGN})

    if(NOT T_NAME)
        message(FATAL_ERROR "oop_task: не задан обязательный параметр NAME")
    endif()
    if(NOT T_SOURCES AND NOT T_MAIN)
        message(FATAL_ERROR "oop_task(${T_NAME}): нужен хотя бы один файл в SOURCES или MAIN")
    endif()
    if(T_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "oop_task(${T_NAME}): непонятные аргументы: ${T_UNPARSED_ARGUMENTS}. "
            "Допустимы только NAME, SOURCES, MAIN, TESTS, BENCH, CURSES.")
    endif()

    # Задача с пометкой CURSES без библиотеки не собирается целиком: её заголовки
    # могут подключать curses.h, а значит собрать нельзя ни программу, ни тесты.
    # Остальные задачи это не затрагивает.
    if(T_CURSES AND NOT OOP_HAVE_CURSES)
        message(STATUS "OOP: задача ${T_NAME} пропущена, нет curses")
        return()
    endif()

    # Код задачи. Заголовки берутся из папки самой задачи.
    add_library(${T_NAME}_lib OBJECT ${T_SOURCES})
    target_include_directories(${T_NAME}_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(${T_NAME}_lib PUBLIC oop_flags)

    # Подключаем PUBLIC: пути к заголовкам curses нужны всем, кто пользуется
    # библиотекой задачи, включая тесты. На Linux и macOS заголовки лежат
    # в системных каталогах, а на Windows - в скачанном PDCurses, и без этого
    # сборка падает на 'Cannot open include file: curses.h'.
    if(T_CURSES)
        target_link_libraries(${T_NAME}_lib PUBLIC oop_curses)
    endif()

    if(T_MAIN)
        add_executable(${T_NAME} ${T_MAIN})
        target_link_libraries(${T_NAME} PRIVATE ${T_NAME}_lib)
    endif()

    if(T_TESTS)
        add_executable(${T_NAME}_tests ${T_TESTS})
        target_link_libraries(${T_NAME}_tests PRIVATE ${T_NAME}_lib GTest::gtest_main)
        # Поиск утечек включён по умолчанию только на Linux; на macOS его нет,
        # и явное detect_leaks=1 там приводит к отказу запуска - поэтому не задаём.
        gtest_discover_tests(${T_NAME}_tests
            TEST_PREFIX "${T_NAME}."
            PROPERTIES ENVIRONMENT "UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1"
        )
    endif()

    # Замеры производительности собираются только пресетом bench.
    # В обычной отладочной сборке их результаты бессмысленны, поэтому цель не создаётся.
    if(T_BENCH AND OOP_BENCHMARKS)
        add_executable(${T_NAME}_bench ${T_BENCH})
        target_link_libraries(${T_NAME}_bench PRIVATE ${T_NAME}_lib benchmark::benchmark_main)
    endif()

    message(STATUS "OOP: задача ${T_NAME}")
endfunction()

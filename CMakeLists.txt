cmake_minimum_required(VERSION 3.21)

project(nsuoop-cpp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# compile_commands.json нужен clang-tidy, clangd и подсказкам в редакторе
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ============================================================================
# Проверки курса. Включаются пресетами (см. README.md), руками трогать не нужно.
# ============================================================================
option(OOP_WERROR   "Считать предупреждения компилятора ошибками" ON)
option(OOP_SANITIZE "Собрать с санитайзерами (ошибки памяти и UB)" OFF)
option(OOP_COVERAGE "Собрать со сбором покрытия кода тестами" OFF)
option(OOP_TIDY     "Запускать clang-tidy при сборке" OFF)
option(OOP_BENCHMARKS "Собирать замеры производительности (Google Benchmark)" OFF)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(OopFlags)
include(OopCurses)

# ============================================================================
# GoogleTest
# ============================================================================
include(FetchContent)
FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.15.2.zip
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
# Windows: не давать GoogleTest переопределять настройки рантайма
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# ============================================================================
# Google Benchmark - только когда включён пресет bench.
# Библиотека тяжёлая, качать её при каждой обычной сборке незачем.
# ============================================================================
if(OOP_BENCHMARKS)
    if(NOT CMAKE_BUILD_TYPE STREQUAL "Release" AND NOT CMAKE_CONFIGURATION_TYPES)
        message(WARNING
            "Замеры производительности собираются НЕ в конфигурации Release. "
            "Результаты будут бессмысленными: пользуйтесь пресетом bench.")
    endif()
    set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
    set(BENCHMARK_ENABLE_GTEST_TESTS OFF CACHE BOOL "" FORCE)
    set(BENCHMARK_USE_BUNDLED_GTEST OFF CACHE BOOL "" FORCE)
    set(benchmark_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_Declare(
        benchmark
        URL https://github.com/google/benchmark/archive/refs/tags/v1.9.4.zip
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    FetchContent_MakeAvailable(benchmark)
endif()

# clang-tidy включаем ПОСЛЕ GoogleTest, иначе он проверял бы и его код тоже.
if(OOP_TIDY)
    find_program(OOP_CLANG_TIDY NAMES clang-tidy)
    if(OOP_CLANG_TIDY)
        set(CMAKE_CXX_CLANG_TIDY "${OOP_CLANG_TIDY}")
        message(STATUS "OOP: clang-tidy включён (${OOP_CLANG_TIDY})")
    else()
        message(FATAL_ERROR
            "clang-tidy не найден. Установка: Ubuntu 'sudo apt install clang-tidy', "
            "macOS 'brew install llvm', Windows - компонент 'C++ Clang tools for Windows' "
            "в установщике Visual Studio.")
    endif()
endif()

enable_testing()
include(GoogleTest)
include(OopTask)

# ============================================================================
# Задачи
# Каждая подпапка в tasks/ со своим CMakeLists.txt подключается автоматически.
# Добавили новую папку - заново выполните 'cmake --preset dev'.
# ============================================================================
include(OopFormat)
include(OopTidy)

file(GLOB OOP_TASK_DIRS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/tasks ${CMAKE_CURRENT_SOURCE_DIR}/tasks/*)
foreach(task_dir IN LISTS OOP_TASK_DIRS)
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tasks/${task_dir}/CMakeLists.txt)
        add_subdirectory(tasks/${task_dir})
    endif()
endforeach()

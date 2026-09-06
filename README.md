# Шаблон проекта для курса "ООП (С++)" ФИТ НГУ

Заготовка репозитория на [CMake](https://cmake.org/download/) с тестами
[GoogleTest](https://github.com/google/googletest) и настроенными проверками качества кода.
Работает одинаково на Linux, macOS и Windows.

Все задачи курса живут в **одном** репозитории, каждая - отдельной папкой в `tasks/`.
Настраивать сборку заново для каждой задачи не нужно.

## Что установить

| Система | Компилятор | CMake |
|---|---|---|
| Windows | Visual Studio 2022 Community, компонент "Разработка классических приложений на C++" | идёт с Visual Studio, либо [отдельно](https://cmake.org/download/) |
| Linux | `sudo apt install build-essential` | `sudo apt install cmake` |
| macOS | `xcode-select --install` | `brew install cmake` |

Проверка: `cmake --version` должна показать 3.21 или новее.

## Первый запуск

Из корня репозитория. Папку `build` создавать руками не нужно.

```bash
cmake --preset dev          # настроить (один раз)
cmake --build --preset dev  # собрать
ctest --preset dev          # прогнать тесты
```

Должно собраться и пройти 2 теста из папки `tasks/example`.

Запуск программы:

```bash
./build/dev/tasks/example/example              # Linux / macOS
.\build\dev\tasks\example\Debug\example.exe    # Windows
```

> Visual Studio, CLion и VS Code (расширение CMake Tools) читают `CMakePresets.json` сами:
> откройте папку репозитория, и пресеты появятся в списке конфигураций.

## Как добавить свою задачу

1. Скопируйте папку `tasks/example` в `tasks/<имя задачи>`, например `tasks/task1b`.
2. Переименуйте файлы и пространство имён под свою задачу.
3. Поправьте `tasks/<имя>/CMakeLists.txt`:

```cmake
oop_task(
  NAME    task1b              # имя задачи, оно же имя исполняемого файла
  SOURCES word_count.cpp      # файлы реализации (без main.cpp и без тестов)
  MAIN    main.cpp            # файл с функцией main, можно не указывать
  TESTS   word_count_test.cpp # файлы тестов, можно не указывать
)
```

4. Выполните `cmake --preset dev` заново - новая папка подхватится автоматически.

Заголовочные `.h`-файлы в `CMakeLists.txt` перечислять не нужно: они не образуют отдельных
единиц трансляции. `.cpp`-файлы - нужно.

Итоговая структура:

```
tasks/
  task1a/    CMakeLists.txt, module1.h/.cpp, module2.h/.cpp, main.cpp
  task1b/    CMakeLists.txt, word_count.h/.cpp, main.cpp, word_count_test.cpp
  task2/     CMakeLists.txt, bit_array.h/.cpp, bit_array_test.cpp
  ...
```

## Работа с одной задачей

Когда задач в репозитории несколько, пересобирать и прогонять всё каждый раз незачем.
`oop_task(NAME task1b ...)` заводит цели с предсказуемыми именами:

| Цель | Что это |
|---|---|
| `task1b` | Исполняемая программа (есть, если задан `MAIN`) |
| `task1b_tests` | Тесты задачи (есть, если задан `TESTS`) |
| `task1b_lib` | Код задачи, только компиляция без линковки |
| `task1b_bench` | Замеры (только в пресете `bench`) |

Собрать и запустить одну задачу:

```bash
cmake --build --preset dev --target task1b      # собрать только её
./build/dev/tasks/task1b/task1b                 # запустить (Linux / macOS)
.\build\dev\tasks\task1b\Debug\task1b.exe    # запустить (Windows)
```

Прогнать тесты только одной задачи - имена тестов начинаются с её имени:

```bash
cmake --build --preset dev --target task1b_tests
ctest --preset dev -R '^task1b\.'
```

Запустить один конкретный тест или группу - напрямую через тестовый файл,
так виден подробный вывод и можно фильтровать по шаблону:

```bash
./build/dev/tasks/task1b/task1b_tests                          # все тесты задачи
./build/dev/tasks/task1b/task1b_tests --gtest_list_tests       # какие вообще есть
./build/dev/tasks/task1b/task1b_tests --gtest_filter='*Empty*' # только подходящие
```

Посмотреть список всех целей в проекте:

```bash
cmake --build --preset dev --target help
```

Проверки стиля и форматирования (`tidy`, `format`, `format-check`) работают сразу
по всем задачам - разделения по задачам у них нет.

## Проверки перед сдачей

Задача принимается, только если проходят все проверки ниже. Каждая - одна команда.
Запускайте их не в последний день: чем раньше, тем дешевле правки.

### 1. Сборка без предупреждений (все три платформы)

```bash
cmake --preset dev
cmake --build --preset dev
ctest --preset dev
```

Компилятор настроен строго: **любое предупреждение останавливает сборку**. Это не придирка -
включённые проверки ловят настоящие ошибки:

| Проверка | Что находит |
|---|---|
| `-Wconversion` | Неявная потеря данных: `double` в `int`, `int` в `int16_t`. Число тихо меняется |
| `-Wsign-conversion` | Отрицательный `int` превращается в огромный `size_t`, и проверка `i < v.size()` перестаёт работать |
| `-Wshadow` | Локальная переменная закрывает поле класса, присваивание уходит не туда |
| `-Wnon-virtual-dtor` | Удаление наследника через указатель на базу без виртуального деструктора |
| `-Woverloaded-virtual` | Метод наследника прячет виртуальный метод базы вместо переопределения |

На Windows тот же смысл несут `/W4 /WX /permissive-`.

Пока пишете код, остановку на предупреждениях можно временно снять пресетом `relaxed`.
**Сдавать нужно с `dev`.**

```bash
cmake --preset relaxed && cmake --build --preset relaxed
```

### 2. Санитайзеры: ошибки памяти и неопределённое поведение

```bash
cmake --preset asan
cmake --build --preset asan
ctest --preset asan
```

Санитайзер - это дополнительные проверки, которые компилятор встраивает прямо в программу.
При ошибке программа падает с подробным отчётом (файл, строка, стек вызовов) в тот момент,
когда ошибка произошла, вместо того чтобы "иногда работать, а иногда нет". Находит:

- выход за границы массива, вектора или строки;
- обращение к освобождённой памяти и повторное освобождение;
- утечки памяти (только Linux);
- переполнение знакового целого, сдвиг на число разрядов больше размера типа,
  разыменование нулевого указателя. Всё это - **неопределённое поведение**,
  то есть по стандарту программа имеет право сделать что угодно.

| Система | Ошибки памяти | Неопределённое поведение | Утечки |
|---|---|---|---|
| Linux | да | да | да |
| macOS | да | да | нет |
| Windows (MSVC) | да | нет | нет |

Из-за этой таблицы полный набор проверок вы получаете в GitHub Actions,
где всё гоняется на Linux.

### 3. Статический анализ

```bash
cmake --preset tidy
cmake --build --preset tidy
```

`clang-tidy` читает код, не запуская его, и находит подозрительные места по набору правил
из файла `.clang-tidy`.

Установка: Ubuntu `sudo apt install clang-tidy`, macOS `brew install llvm`
(и добавить в `PATH` путь из `brew --prefix llvm`), Windows - компонент
"C++ Clang tools for Windows" в установщике Visual Studio.

### 4. Покрытие кода тестами (Linux и macOS)

```bash
cmake --preset coverage
cmake --build --preset coverage
ctest --preset coverage
```

Показывает, какие строки вашего кода ни разу не выполнились за время тестов.
Для HTML-отчёта нужен `lcov` (`sudo apt install lcov` / `brew install lcov`):

```bash
lcov --capture --directory build/coverage --output-file coverage.info --ignore-errors mismatch,gcov
lcov --remove coverage.info '/usr/*' '*/_deps/*' '*_test.cpp' '*/main.cpp' --output-file coverage.info --ignore-errors unused
lcov --list coverage.info
genhtml coverage.info --output-directory coverage-html
```

Отчёт откроется в `coverage-html/index.html`. На Windows покрытие не собирается -
берите отчёт из GitHub Actions.

### 5. Стиль кода: имена и форматирование

```bash
cmake --build --preset dev --target format-check   # проверить форматирование
cmake --build --preset dev --target format         # исправить форматирование
```

Форматирование делает `clang-format` по файлу `.clang-format`. Руками ничего выравнивать
не нужно, спорить о пробелах тоже. Ключевое: открывающая скобка на **той же строке**,
отступ 2 пробела, тело `if`/`for`/`while` всегда в фигурных скобках.

Имена проверяет `clang-tidy` (пресет `tidy`). Ориентир - стандартная библиотека:
`push_back`, `to_string`, `size`. Официального стандарта оформления в C++ нет,
поэтому курс следует стилю того, что вы расширяете.

| Что | Правило | Пример |
|---|---|---|
| Классы, структуры, перечисления | `CamelCase` | `BitArray`, `WordCount` |
| Функции и методы | `lower_case` | `push_back`, `split_words` |
| Переменные и параметры | `lower_case` | `num_bits` |
| Поля класса | `lower_case_` | `size_`, `data_` |
| Константы `constexpr` | `kCamelCase` | `kWordBits` |
| Пространства имён | `lower_case` | `word_count` |
| Макросы | `UPPER_CASE` | |

С большой буквы пишутся только типы. Функций с большой буквы в курсе нет.

Установка `clang-format`: Ubuntu `sudo apt install clang-format`,
macOS `brew install llvm`, Windows - вместе с компонентом
"C++ Clang tools for Windows" в установщике Visual Studio.

### 6. GitHub Actions

В `.github/workflows/ci.yml` уже настроен запуск всех проверок при каждом `push`
и Pull Request: сборка и тесты на трёх платформах, санитайзеры, `clang-tidy`,
покрытие с публикацией HTML-отчёта. Настраивать ничего не нужно - запушьте ветку
и смотрите вкладку Actions.

## Замеры производительности

Отдельный пресет на [Google Benchmark](https://github.com/google/benchmark).
Библиотека тяжёлая, поэтому качается только когда нужна - обычные сборки от неё не страдают.

```bash
cmake --preset bench
cmake --build --preset bench
./build/bench/tasks/example/example_bench
```

Пресет `bench` собирает в **Release**. В отладочной сборке измерять нечего: без оптимизаций
числа не имеют отношения к реальности.

Подключается к задаче одним параметром:

```cmake
oop_task(NAME task2 SOURCES bit_array.cpp TESTS bit_array_test.cpp BENCH bit_array_bench.cpp)
```

### Главная ошибка в замерах

Компилятор выбрасывает вычисления, результат которых не используется. Замер вида

```c++
for (auto _ : state) {
  a.method();          // результат никуда не идёт
}
```

измеряет пустой цикл и покажет 0 наносекунд. Это не скорость, это отсутствие кода.
Правильно - показать результат компилятору:

```c++
for (auto _ : state) {
  benchmark::DoNotOptimize(a.method());
}
```

Вторая ловушка того же рода: если компилятор видит точный тип объекта, он заменяет
виртуальный вызов обычным (девиртуализация), и сравнение теряет смысл.
Вызывать нужно через указатель или ссылку на базовый класс.

Смотрите `tasks/example/example_bench.cpp`: там измерены стоимость виртуального вызова,
создания объекта в куче против стека, броска исключения и обращения к часам.

## Состав шаблона

| Файл | Назначение |
|---|---|
| `CMakeLists.txt` | Корневые правила сборки. Папки задач подключаются автоматически |
| `CMakePresets.json` | Готовые наборы флагов: `dev`, `relaxed`, `asan`, `coverage`, `tidy`, `bench`, `release` |
| `cmake/OopFlags.cmake` | Флаги предупреждений, санитайзеров и покрытия по платформам |
| `cmake/OopTask.cmake` | Функция `oop_task()` - описание одной задачи |
| `.clang-tidy` | Правила статического анализа и именования |
| `.clang-format` | Правила форматирования |
| `cmake/OopFormat.cmake` | Цели `format` и `format-check` |
| `.github/workflows/ci.yml` | Автоматический запуск всех проверок на GitHub |
| `tasks/example/` | Задача-образец: копируйте её под свои задачи |
| `tasks/example/example_bench.cpp` | Образец замеров производительности |

## Частые проблемы

| Симптом | Причина и решение |
|---|---|
| `CMake 3.21 or higher is required` | Старый CMake, обновите: <https://cmake.org/download/> |
| Сборка падает на предупреждении в вашем коде | Это и есть проверка. Исправьте причину, а не ставьте приведение типа "чтобы замолчало" |
| Новая папка в `tasks/` не собирается | Выполните `cmake --preset dev` заново: список папок читается при настройке |
| `clang-tidy не найден` | Установите (см. пункт 3) или пользуйтесь остальными пресетами |
| На Windows не находится `.exe` | Ищите в `build\dev\tasks\<задача>\Debug\`: Visual Studio раскладывает по подпапкам конфигураций |
| `detect_leaks is not supported` | Поиск утечек есть только на Linux, на macOS и Windows это нормально |
| Долгая первая сборка | GoogleTest скачивается и собирается один раз на каждый пресет |

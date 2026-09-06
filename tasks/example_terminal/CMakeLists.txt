# Curses primer: RAII wrapper + fixed-step real-time loop (not a game
# template, see README.md). Copy tasks/example instead of this one for a
# regular (non-curses) task.
oop_task(
  NAME    example_terminal
  SOURCES terminal_screen.cpp
  MAIN    main.cpp
  CURSES
)

#pragma once

#include <curses.h>

#include <cstdint>
#include <string>

// RAII wrapper around curses. The constructor puts the terminal into curses
// mode, the destructor always calls endwin() - including while the stack is
// unwinding because of an exception - so the terminal is never left in a
// broken state.
class TerminalScreen {
public:
  // Color pair ids passed to init_pair() during construction.
  enum class Color : std::uint8_t { kDefault = 1, kAccent = 2 };

  // Throws std::runtime_error if the terminal has no color support.
  TerminalScreen();
  ~TerminalScreen();

  TerminalScreen(const TerminalScreen&) = delete;
  TerminalScreen& operator=(const TerminalScreen&) = delete;

  [[nodiscard]] int width() const;
  [[nodiscard]] int height() const;

  void clear() const;
  void refresh() const;

  void draw_text(int y, int x, const std::string& text) const;
  void draw_border() const;
  void set_color(Color color) const;
  void reset_color() const;

  // Non-blocking key read: returns ERR (from curses.h) when nothing was
  // typed since the last call.
  [[nodiscard]] int read_key() const;

private:
  WINDOW* window_;
};

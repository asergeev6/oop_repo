#include "terminal_screen.h"

#include <clocale>
#include <stdexcept>

namespace {

// setlocale() must run before initscr() reads terminal capabilities.
WINDOW* start_curses() {
  static_cast<void>(std::setlocale(LC_ALL, ""));
  return initscr();
}

}  // namespace

TerminalScreen::TerminalScreen() : window_(start_curses()) {
  cbreak();
  noecho();
  curs_set(0);
  keypad(window_, TRUE);
  nodelay(window_, TRUE);  // getch() returns immediately instead of blocking

  if (!has_colors()) {
    endwin();
    throw std::runtime_error("terminal has no color support");
  }
  start_color();
  init_pair(static_cast<int>(Color::kDefault), COLOR_WHITE, COLOR_BLACK);
  init_pair(static_cast<int>(Color::kAccent), COLOR_YELLOW, COLOR_BLUE);
}

// Runs even while the stack unwinds due to an exception, so curses mode is
// never left active on a terminal that has already printed an error message.
TerminalScreen::~TerminalScreen() {
  endwin();
}

int TerminalScreen::width() const {
  return getmaxx(window_);
}
int TerminalScreen::height() const {
  return getmaxy(window_);
}

void TerminalScreen::clear() const {
  wclear(window_);
}
void TerminalScreen::refresh() const {
  wrefresh(window_);
}

void TerminalScreen::draw_text(int y, int x, const std::string& text) const {
  mvwaddstr(window_, y, x, text.c_str());
}

void TerminalScreen::draw_border() const {
  box(window_, 0, 0);
}

void TerminalScreen::set_color(Color color) const {
  wattron(window_, COLOR_PAIR(static_cast<int>(color)));
}

void TerminalScreen::reset_color() const {
  wattrset(window_, A_NORMAL);
}

int TerminalScreen::read_key() const {
  return wgetch(window_);
}

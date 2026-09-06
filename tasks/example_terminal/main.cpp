// Demonstrates one thing: a real-time loop for a terminal UI (curses) with
// a fixed-step world update decoupled from rendering and input. This is
// NOT a game template - see README.md next to this file for what to take
// from it and what task 3 requires beyond it.

#include <curses.h>

#include <algorithm>
#include <chrono>
#include <iostream>
#include <string>
#include <thread>

#include "terminal_screen.h"

namespace {

constexpr int kUpdatesPerSecond = 30;
constexpr std::chrono::duration<double> kStep{1.0 / kUpdatesPerSecond};

struct World {
  int ball_x = 5;
  int ball_y = 5;
  int ball_dx = 1;
  int ball_dy = 1;
  int player_x = 1;
  int player_y = 1;
  int ticks = 0;
};

// One fixed-size simulation step. Runs zero or more times per rendered
// frame, so the ball keeps moving at the same speed regardless of fps.
void update(World& world, int min_x, int min_y, int max_x, int max_y) {
  world.ball_x += world.ball_dx;
  world.ball_y += world.ball_dy;
  if (world.ball_x <= min_x || world.ball_x >= max_x) {
    world.ball_dx = -world.ball_dx;
  }
  if (world.ball_y <= min_y || world.ball_y >= max_y) {
    world.ball_dy = -world.ball_dy;
  }
  ++world.ticks;
}

void handle_key(World& world, int key, int min_x, int min_y, int max_x, int max_y) {
  switch (key) {
    case KEY_LEFT:
      world.player_x = std::max(min_x, world.player_x - 1);
      break;
    case KEY_RIGHT:
      world.player_x = std::min(max_x, world.player_x + 1);
      break;
    case KEY_UP:
      world.player_y = std::max(min_y, world.player_y - 1);
      break;
    case KEY_DOWN:
      world.player_y = std::min(max_y, world.player_y + 1);
      break;
    default:
      break;
  }
}

void draw(const TerminalScreen& screen, const World& world) {
  screen.clear();
  screen.draw_border();
  screen.draw_text(
      0, 2, "example_terminal: arrows move @, q quits, ticks=" + std::to_string(world.ticks));

  screen.set_color(TerminalScreen::Color::kAccent);
  screen.draw_text(world.ball_y, world.ball_x, "*");
  screen.reset_color();

  screen.draw_text(world.player_y, world.player_x, "@");
  screen.refresh();
}

}  // namespace

int main() {
  try {
    TerminalScreen screen;
    World world;
    constexpr int kMinX = 1;
    constexpr int kMinY = 1;

    auto previous = std::chrono::steady_clock::now();
    std::chrono::duration<double> accumulator{0};

    int key = ERR;
    while (key != 'q') {
      const auto now = std::chrono::steady_clock::now();
      accumulator += now - previous;
      previous = now;

      const int max_x = screen.width() - 2;
      const int max_y = screen.height() - 2;

      // Time-based accumulator, not getch()'s timeout: the update rate
      // stays constant even when a frame takes longer to render.
      while (accumulator >= kStep) {
        update(world, kMinX, kMinY, max_x, max_y);
        accumulator -= kStep;
      }

      key = screen.read_key();  // ERR when nothing was typed (non-blocking)
      handle_key(world, key, kMinX, kMinY, max_x, max_y);
      draw(screen, world);

      std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
  } catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << '\n';
    return 1;
  }
  return 0;
}

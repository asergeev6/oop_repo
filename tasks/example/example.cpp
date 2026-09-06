#include "example.h"

namespace example {

int plus(int x, int y) {
  return x + y;
}

std::string say_hello(const std::string& name) {
  return "Hello, " + name + "!";
}

}  // namespace example

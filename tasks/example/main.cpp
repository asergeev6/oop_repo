#include <iostream>

#include "example.h"

int main() {
  std::cout << example::say_hello("world") << '\n';
  std::cout << "2 + 3 = " << example::plus(2, 3) << '\n';
  return 0;
}

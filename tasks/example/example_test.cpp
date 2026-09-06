#include "example.h"

#include "gtest/gtest.h"

namespace {

TEST(ExampleTest, Plus) {
  EXPECT_EQ(example::plus(2, 3), 5);
  EXPECT_EQ(example::plus(-1, 1), 0);
}

TEST(ExampleTest, SayHello) {
  EXPECT_EQ(example::say_hello("world"), "Hello, world!");
}

}  // namespace

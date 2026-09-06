// Google Benchmark measurements.
//
// Golden rule: wrap every result in benchmark::DoNotOptimize, or the compiler
// discards the computation and you measure an empty loop. Example: without
// it, timing a method that returns 0 reports 0 ns - that's missing code,
// not real speed.
//
// Run with the bench preset (Release build - otherwise the numbers are meaningless).

#include <benchmark/benchmark.h>

#include <chrono>
#include <memory>
#include <stdexcept>

#include "example.h"

namespace {

class Plain {
public:
  int method() const { return value_; }
  int method_throw() const { throw std::runtime_error("Error"); }

private:
  int value_ = 0;
};

class Virtual {
public:
  virtual ~Virtual() = default;
  virtual int method() const { return value_; }
  virtual int method_throw() const { throw std::runtime_error("Error"); }

private:
  int value_ = 0;
};

void BM_ConstructOnStack(benchmark::State& state) {
  for (auto _ : state) {
    Plain p;
    benchmark::DoNotOptimize(p);
  }
}
BENCHMARK(BM_ConstructOnStack);

void BM_ConstructOnStackVirtual(benchmark::State& state) {
  for (auto _ : state) {
    Virtual v;
    benchmark::DoNotOptimize(v);
  }
}
BENCHMARK(BM_ConstructOnStackVirtual);

// A paired new+delete: an unmatched new leaks (the asan preset would catch
// it) and would skew the measurement anyway.
void BM_ConstructOnHeap(benchmark::State& state) {
  for (auto _ : state) {
    auto p = std::make_unique<Plain>();
    benchmark::DoNotOptimize(p);
  }
}
BENCHMARK(BM_ConstructOnHeap);

void BM_ConstructOnHeapVirtual(benchmark::State& state) {
  for (auto _ : state) {
    auto v = std::make_unique<Virtual>();
    benchmark::DoNotOptimize(v);
  }
}
BENCHMARK(BM_ConstructOnHeapVirtual);

// A direct call is often inlined, a virtual one is not. Calling through a
// base pointer keeps the comparison honest, or the compiler would see the
// concrete type and devirtualize the call.
void BM_CallMethod(benchmark::State& state) {
  const Plain p;
  for (auto _ : state) {
    benchmark::DoNotOptimize(p.method());
  }
}
BENCHMARK(BM_CallMethod);

void BM_CallVirtualMethod(benchmark::State& state) {
  const auto owner = std::make_unique<Virtual>();
  const Virtual* v = owner.get();
  benchmark::DoNotOptimize(v);
  for (auto _ : state) {
    benchmark::DoNotOptimize(v->method());
  }
}
BENCHMARK(BM_CallVirtualMethod);

// Throwing costs orders of magnitude more than returning a value - use
// exceptions for errors, not for control flow.
void BM_ThrowAndCatch(benchmark::State& state) {
  const Plain p;
  for (auto _ : state) {
    try {
      benchmark::DoNotOptimize(p.method_throw());
    } catch (const std::runtime_error&) {
      benchmark::ClobberMemory();
    }
  }
}
BENCHMARK(BM_ThrowAndCatch);

void BM_ThrowAndCatchVirtual(benchmark::State& state) {
  const auto owner = std::make_unique<Virtual>();
  const Virtual* v = owner.get();
  benchmark::DoNotOptimize(v);
  for (auto _ : state) {
    try {
      benchmark::DoNotOptimize(v->method_throw());
    } catch (const std::runtime_error&) {
      benchmark::ClobberMemory();
    }
  }
}
BENCHMARK(BM_ThrowAndCatchVirtual);

// steady_clock works on all three platforms; clock_gettime(CLOCK_MONOTONIC_RAW)
// does not exist on Windows.
void BM_ClockNow(benchmark::State& state) {
  for (auto _ : state) {
    benchmark::DoNotOptimize(std::chrono::steady_clock::now());
  }
}
BENCHMARK(BM_ClockNow);

// Clock granularity: how long until two consecutive reads differ.
void BM_ClockGranularity(benchmark::State& state) {
  for (auto _ : state) {
    const auto start = std::chrono::steady_clock::now();
    auto next = start;
    while (next == start) {
      next = std::chrono::steady_clock::now();
    }
    benchmark::DoNotOptimize(next);
  }
}
BENCHMARK(BM_ClockGranularity);

void BM_Plus(benchmark::State& state) {
  for (auto _ : state) {
    benchmark::DoNotOptimize(example::plus(2, 3));
  }
}
BENCHMARK(BM_Plus);

}  // namespace

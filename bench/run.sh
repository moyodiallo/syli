#!/bin/bash
set -e
cd "$(dirname "$0")"
ROOT="$(cd .. && pwd)"

export SYLI_RUNTIME_LIB="$ROOT/runtime/cmake-build/Release/libsyliruntime.a"

build() {
  echo "Building $1..."
  cd "$ROOT"
  dune exec sylic -- build "bench/$1.sy" 2>/dev/null
  mv "$1.exe" "bench/$1.exe" 2>/dev/null || true
  cd "$OLDPWD"
}

bench() {
  echo ""
  echo "=== $1 ==="
  hyperfine -w 3 -m 5 --shell=none "./$1.exe"
}

bench_mem() {
  local exe="$1"
  case "$(uname -s)" in
    Linux) command time -v "$exe" 2>&1 | grep 'Maximum resident' | awk '{print $6}' ;;
    *) peak=$(command time -l "$exe" 2>&1 | grep 'maximum resident set size' | awk '{print $NF}')
       echo $((peak / 1024)) ;;
  esac
}

BENCHMARKS="tak queens clos clos4"

for b in $BENCHMARKS; do
  build "$b"
done

for b in $BENCHMARKS; do
  bench "$b"
done

echo ""
echo "=== Memory usage peak ==="
for b in $BENCHMARKS; do
  mem=$(bench_mem "./$b.exe")
  printf "  %-8s %s KB\n" "$b" "${mem:-N/A}"
done

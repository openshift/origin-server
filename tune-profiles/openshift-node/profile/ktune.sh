start() {
  set_cpu_governor performance
  set_transparent_hugepages always
  echo 65536 > /selinux/avc/cache_threshold
  return 0
}

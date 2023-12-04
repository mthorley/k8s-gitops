helm template \
  frigate \
  blakeblackshear/frigate \
  -n frigate \
  -f values.yaml > frigate-stack.yaml
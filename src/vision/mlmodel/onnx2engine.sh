# Linux (Jetson-based) Operation Only
/usr/src/tensorrt/bin/trtexec           \
--onnx=onnx/tennis_v2.onnx              \
--saveEngine=engine/tennis_v2.engine    \
--fp16
import struct
import metal

# 1. Get the default GPU device
device = Metal.MTLCreateSystemDefaultDevice()

# 2. Create a Command Queue
command_queue = device.newCommandQueue()

# 3. Convert Python floats to raw 32-bit C-float bytes
data = [1.0, 2.0, 3.0, 4.0]
data_bytes = struct.pack(f"{len(data)}f", *data)

# 4. Create data buffer
buffer = device.newBufferWithBytes_length_options_(
    data_bytes,
    len(data_bytes),
    Metal.MTLResourceStorageModeShared,
)

print(f"GPU Device: {device.name()}")
print(f"Buffer created: {buffer.length()} bytes")
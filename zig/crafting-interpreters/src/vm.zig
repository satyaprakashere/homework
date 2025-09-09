const std = @import("std");
const Num = @import("base.zig").Num;
const RChunk = @import("chunk.zig");
const Chunk = RChunk.Chunk;

pub const VM = struct {
    allocator: std.mem.Allocator,
    chunk: *Chunk,
    stack: std.ArrayList(Num),

    stackTop: *Num,
    ip: RChunk.InstructionPointer,

    pub fn initChunk(allocator: std.mem.Allocator, chunk: *Chunk) !VM {
        return VM {
            .allocator = allocator,
            .chunk = chunk,
            .stack = try std.ArrayList(Num).initCapacity(allocator, 1024),
            .stackTop = undefined,
            .ip = RChunk.InstructionPointer.init(chunk),
        };
    }

    pub fn deinit(self: *VM) void {
        self.stack.deinit(self.allocator);
    }

    pub fn interpret(self: *VM, chunk: *Chunk) InterpretResult {
        self.chunk = chunk;
        self.ip = self.chunk.code;
        return self.run();
    }

    pub fn run(self: *VM) InterpretResult {
        while (true) {
            const instruction:RChunk.OpCode = @enumFromInt(self.ip.readByte());
            switch (instruction) {
                .OP_CONSTANT => {
                    const constant = self.chunk.constants.items[self.ip.readByte()];
                    self.push(constant);
                },
                .OP_RETURN => {
                    self.pop();
                    return InterpretResult.INTERPRET_OK;
                },
            }
        }
    }
};

pub const InterpretResult = enum {
    INTERPRET_OK,
    INTERPRET_COMPILE_ERROR,
    INTERPRET_RUNTIME_ERROR,
};

const std = @import("std");
const Num = @import("base.zig").Num;
const RChunk = @import("chunk.zig");
const Chunk = RChunk.Chunk;

pub const VM = struct {
    chunk: *Chunk,
    stack: std.ArrayList(Num),

    stackTop: *Num,
    ip: RChunk.InstructionPointer,

    pub fn initChunk(allocator: std.mem.Allocator, chunk: *Chunk) VM {
        return VM {
            .chunk = chunk,
            .stack = std.ArrayList(Num).init(allocator),
            .ip = RChunk.InstructionPointer.init(chunk),
        };
    }

    pub fn deinit(self: *VM) void {
        self.stack.deinit();
        self.ip.deinit();
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

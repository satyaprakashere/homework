const std = @import("std");
const base = @import("base.zig");
pub const OpCode = @import("op.zig").CODE;

pub const InstructionPointer = struct {
    chunk: *Chunk,
    offset: usize,

    pub fn init(chunk: *Chunk) InstructionPointer {
        return InstructionPointer {
            .chunk = chunk,
            .offset = 0,
        };
    }

    pub fn readByte(self: *InstructionPointer) u8 {
        const byte = self.chunk.code.items[self.offset];
        self.offset += 1;
        return byte;
    }

    pub fn readConstant(self: *InstructionPointer) base.Num {
        const constantIndex = self.readByte();
        return self.chunk.constants.items[constantIndex];
    }
};

pub const Chunk = struct {
    count: u32,
    capacity: u32,
    allocator: std.mem.Allocator,
    code: std.ArrayList(u8),
    constants: std.ArrayList(base.Num),

    pub fn init(allocator: std.mem.Allocator) !Chunk {
        return Chunk {
            .count = 0,
            .capacity = 1024,
            .allocator = allocator,
            .code = try std.ArrayList(u8).initCapacity(allocator, 1024),
            .constants = try std.ArrayList(base.Num).initCapacity(allocator, 1024)
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.count = 0;
        self.capacity = 0;
        self.code.deinit(self.allocator);
        self.constants.deinit(self.allocator);
    }

    pub fn writeChunk(self: *Chunk, code: OpCode) !void {
        if (self.count == self.capacity) {
            try growChunk(self);
        }
        try self.code.append(self.allocator, @intFromEnum(code));
        self.count += 1;
    }

    pub fn growChunk(self: *Chunk) !void {
        const newCapacity = self.capacity + self.capacity / 2;
        try self.code.resize(self.allocator, newCapacity);
        self.capacity = newCapacity;
    }

    pub fn deassembleChunk(self: *Chunk, name: []const u8) void  {
        std.debug.print("=== {s} ===\n", .{name});
        var offset: usize = 0;
        while (offset < self.count) {
            offset = deassembleInstruction(self, offset);
        }
    }

    fn deassembleInstruction(self: *Chunk, offset: usize) usize {
        std.debug.print("at index {d} : ", .{offset});
        const instruction: OpCode = @enumFromInt(self.code.items[offset]);
        switch (instruction) {
            OpCode.RETURN => std.debug.print("RETURN\n", .{}),
            OpCode.CONSTANT => {
                std.debug.print("CONSTANT\n", .{});
            },
            OpCode.ADD => std.debug.print("ADD\n", .{}),
            OpCode.SUB => std.debug.print("SUB\n", .{}),
            OpCode.MUL => std.debug.print("MUL\n", .{}),
            OpCode.DIV => std.debug.print("DIV\n", .{}),
            OpCode.NIL => std.debug.print("Invalid Operation \n", .{}),
        }
        return offset + 1;
    }

    pub fn addConstant(self: *Chunk, value: base.Num) !usize{
        try self.constants.append(self.allocator, value);
        return self.constants.items.len-1;
    }
};


pub fn printValue(value : base.Num) void {
    std.debug.print("Value: {d}\n", .{value});
}

test "Chunk" {

}

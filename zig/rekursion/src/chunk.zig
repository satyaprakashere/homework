const std = @import("std");
const Allocator = std.mem.Allocator;
const Value = @import("value.zig").Value;
const ValueArray = @import("value.zig").ValueArray;

pub const OpCode = enum(u8) {
    op_constant,
    op_nil,
    op_true,
    op_false,
    op_add,
    op_subtract,
    op_multiply,
    op_divide,
    op_negate, // Unary minus
    op_return,
    _,
};

pub const Chunk = struct {
    code: std.ArrayList(u8),
    constants: ValueArray,
    lines: std.ArrayList(usize),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Chunk {
        return Chunk{
            .code = .empty,
            .constants = ValueArray.init(allocator),
            .lines = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.code.deinit(self.allocator);
        self.constants.deinit();
        self.lines.deinit(self.allocator);
    }

    pub fn write(self: *Chunk, byte: u8, line: usize) !void {
        try self.code.append(self.allocator, byte);
        try self.lines.append(self.allocator, line);
    }

    pub fn addConstant(self: *Chunk, value: Value) !usize {
        try self.constants.write(value);
        return self.constants.values.items.len - 1;
    }

    // Disassemble instruction for debugging
    pub fn disassemble(self: *Chunk, name: []const u8) void {
        std.debug.print("== {s} ==\n", .{name});

        var offset: usize = 0;
        while (offset < self.code.items.len) {
            offset = self.disassembleInstruction(offset);
        }
    }

    pub fn disassembleInstruction(self: *Chunk, offset: usize) usize {
        std.debug.print("{d:0>4} ", .{offset});

        if (offset > 0 and self.lines.items[offset] == self.lines.items[offset - 1]) {
            std.debug.print("   | ", .{});
        } else {
            std.debug.print("{d:4} ", .{self.lines.items[offset]});
        }

        const instruction: OpCode = @enumFromInt(self.code.items[offset]);
        switch (instruction) {
            .op_constant => return self.constantInstruction("OP_CONSTANT", offset),
            .op_nil => return self.simpleInstruction("OP_NIL", offset),
            .op_true => return self.simpleInstruction("OP_TRUE", offset),
            .op_false => return self.simpleInstruction("OP_FALSE", offset),
            .op_add => return self.simpleInstruction("OP_ADD", offset),
            .op_subtract => return self.simpleInstruction("OP_SUBTRACT", offset),
            .op_multiply => return self.simpleInstruction("OP_MULTIPLY", offset),
            .op_divide => return self.simpleInstruction("OP_DIVIDE", offset),
            .op_negate => return self.simpleInstruction("OP_NEGATE", offset),
            .op_return => return self.simpleInstruction("OP_RETURN", offset),
            _ => {
                std.debug.print("Unknown opcode {d}\n", .{@intFromEnum(instruction)});
                return offset + 1;
            },
        }
    }

    fn simpleInstruction(_: *Chunk, name: []const u8, offset: usize) usize {
        std.debug.print("{s}\n", .{name});
        return offset + 1;
    }

    fn constantInstruction(self: *Chunk, name: []const u8, offset: usize) usize {
        const constant_idx = self.code.items[offset + 1];
        std.debug.print("{s:<16} {d:4} '", .{ name, constant_idx });
        self.constants.values.items[constant_idx].print();
        std.debug.print("'\n", .{});
        return offset + 2;
    }
};

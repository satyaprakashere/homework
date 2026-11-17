const std = @import("std");
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;

pub const InterpretResult = enum {
    ok,
    compile_error,
    runtime_error,
};

pub const VM = struct {
    chunk: ?*Chunk,
    ip: usize, // Instruction pointer as index
    stack: std.ArrayList(Value),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) std.mem.Allocator.Error!VM {
        return VM{
            .chunk = null,
            .ip = 0,
            .stack = try std.ArrayList(Value).initCapacity(allocator, 256),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *VM) void {
        self.stack.deinit(self.allocator);
    }

    pub fn interpret(self: *VM, chunk: *Chunk) !InterpretResult {
        self.chunk = chunk;
        self.ip = 0;
        return self.run();
    }

    fn run(self: *VM) !InterpretResult {
        while (true) {
            if (self.chunk == null) return .runtime_error;
            const chunk = self.chunk.?;

            if (self.ip >= chunk.code.items.len) {
                return .ok; // Finished execution
            }

            // Fetch
            const instruction = @as(OpCode, @enumFromInt(chunk.code.items[self.ip]));
            self.ip += 1;

            // Decode & Execute
            switch (instruction) {
                .op_constant => {
                    const constant_idx = self.readByte();
                    const constant = chunk.constants.values.items[constant_idx];
                    try self.push(constant);
                },
                .op_nil => try self.push(Value{ .nil = {} }),
                .op_true => try self.push(Value{ .boolean = true }),
                .op_false => try self.push(Value{ .boolean = false }),
                .op_add => try self.binaryOp(.add),
                .op_subtract => try self.binaryOp(.subtract),
                .op_multiply => try self.binaryOp(.multiply),
                .op_divide => try self.binaryOp(.divide),
                .op_negate => {
                    // Start of arithmetic operations
                    if (!self.peek(0).isFloat()) {
                        self.runtimeError("Operand must be a number.");
                        return .runtime_error;
                    }
                    const v = self.pop().?.asFloat();
                    try self.push(Value{ .float = -v });
                },
                .op_return => {
                    self.printStack(); // For debugging
                    const result = self.pop();
                    result.?.print();
                    std.debug.print("\n", .{});
                    return .ok;
                },
                _ => return .runtime_error,
            }
        }
    }

    fn readByte(self: *VM) u8 {
        const byte = self.chunk.?.code.items[self.ip];
        self.ip += 1;
        return byte;
    }

    fn push(self: *VM, value: Value) !void {
        try self.stack.append(self.allocator, value);
    }

    fn pop(self: *VM) ?Value {
        return self.stack.pop();
    }

    fn peek(self: *VM, distance: usize) Value {
        return self.stack.items[self.stack.items.len - 1 - distance];
    }

    // Helper enum for binary ops
    const BinaryOpType = enum { add, subtract, multiply, divide };

    fn binaryOp(self: *VM, op: BinaryOpType) !void {
        if (!self.peek(0).isFloat() or !self.peek(1).isFloat()) {
            self.runtimeError("Operands must be numbers.");
            // In a real VM we'd return an error here to propagate up
            return;
        }
        const b = self.pop().?.asFloat();
        const a = self.pop().?.asFloat();

        const result = switch (op) {
            .add => a + b,
            .subtract => a - b,
            .multiply => a * b,
            .divide => a / b,
        };
        try self.push(Value{ .float = result });
    }

    fn runtimeError(self: *VM, message: []const u8) void {
        _ = self;
        std.debug.print("Runtime Error: {s}\n", .{message});
        // Print stack trace or line info here
    }

    fn printStack(self: *VM) void {
        std.debug.print("          ", .{});
        for (self.stack.items) |value| {
            std.debug.print("[ ", .{});
            value.print();
            std.debug.print(" ]", .{});
        }
        std.debug.print("\n", .{});
    }
};

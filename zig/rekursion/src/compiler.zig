const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;
const TokenType = @import("scanner.zig").TokenType;
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;

pub const Compiler = struct {
    scanner: Scanner,
    chunk: *Chunk,
    current: @import("scanner.zig").Token,
    previous: @import("scanner.zig").Token,
    hadError: bool,
    panicMode: bool,

    pub fn compile(source: []const u8, chunk: *Chunk) !bool {
        var compiler = Compiler{
            .scanner = Scanner.init(source),
            .chunk = chunk,
            .current = undefined,
            .previous = undefined,
            .hadError = false,
            .panicMode = false,
        };

        compiler.advance();

        while (!compiler.match(.eof)) {
            try compiler.expression();
        }

        try compiler.emitReturn();
        return !compiler.hadError;
    }

    fn advance(self: *Compiler) void {
        self.previous = self.current;

        while (true) {
            self.current = self.scanner.scanToken();
            if (self.current.type != .error_token) break;

            self.errorAtCurrent(self.current.start);
        }
    }

    fn match(self: *Compiler, token_type: TokenType) bool {
        if (!self.check(token_type)) return false;
        self.advance();
        return true;
    }

    fn check(self: *Compiler, token_type: TokenType) bool {
        return self.current.type == token_type;
    }

    fn expression(self: *Compiler) anyerror!void {
        if (self.match(.number)) {
            try self.number();
        } else if (self.match(.left_paren)) {
            try self.list();
        } else {
            self.errorAtCurrent("Expect expression.");
        }
    }

    fn list(self: *Compiler) anyerror!void {
        // We are at the start of a list after '('
        // Scheme lists are (func arg1 arg2 ...)
        // For simple arithmetic like (+ 1 2), we want to push 1, push 2, then ADD.

        // This suggests we need to parse the function name first?
        // Or is it always an operator for now?
        // Let's assume standard prefix notation.

        if (self.match(.identifier)) {
            try self.operatorCall();
        } else {
            // Empty list or other forms?
            self.errorAtCurrent("Expect operator after '('.");
        }
    }

    fn operatorCall(self: *Compiler) anyerror!void {
        const operatorToken = self.previous;

        // Parse arguments
        while (!self.check(.right_paren) and !self.check(.eof)) {
            try self.expression();
        }

        try self.consume(.right_paren, "Expect ')' after arguments.");

        // Emit instruction based on operator
        const op = operatorToken.start;
        if (std.mem.eql(u8, op, "+")) {
            try self.emitByte(@intFromEnum(OpCode.op_add));
        } else if (std.mem.eql(u8, op, "-")) {
            try self.emitByte(@intFromEnum(OpCode.op_subtract));
        } else if (std.mem.eql(u8, op, "*")) {
            try self.emitByte(@intFromEnum(OpCode.op_multiply));
        } else if (std.mem.eql(u8, op, "/")) {
            try self.emitByte(@intFromEnum(OpCode.op_divide));
        } else {
            self.errorAt("Unknown operator.", operatorToken);
        }
    }

    fn number(self: *Compiler) !void {
        const value_str = self.previous.start;
        // Need to terminate string or copy it to parse?
        // Allocating a null-terminated string for parsing
        // Or using `fmt.parseFloat` on slice?

        // Scanner returns slice of source, which might not be null terminated if it's in the middle.
        // `std.fmt.parseFloat` takes a slice, so it should be fine.

        const value = try std.fmt.parseFloat(f64, value_str);
        try self.emitConstant(Value{ .float = value });
    }

    fn consume(self: *Compiler, token_type: TokenType, message: []const u8) !void {
        if (self.current.type == token_type) {
            self.advance();
            return;
        }
        self.errorAtCurrent(message);
    }

    fn emitByte(self: *Compiler, byte: u8) !void {
        try self.chunk.write(byte, self.previous.line);
    }

    fn emitBytes(self: *Compiler, byte1: u8, byte2: u8) !void {
        try self.emitByte(byte1);
        try self.emitByte(byte2);
    }

    fn emitReturn(self: *Compiler) !void {
        try self.emitByte(@intFromEnum(OpCode.op_return));
    }

    fn emitConstant(self: *Compiler, value: Value) !void {
        const constant = try self.chunk.addConstant(value);
        try self.emitBytes(@intFromEnum(OpCode.op_constant), @as(u8, @intCast(constant)));
    }

    fn errorAtCurrent(self: *Compiler, message: []const u8) void {
        self.errorAt(message, self.current);
    }

    fn errorAt(self: *Compiler, message: []const u8, token: @import("scanner.zig").Token) void {
        if (self.panicMode) return;
        self.panicMode = true;
        std.debug.print("[line {d}] Error", .{token.line});

        if (token.type == .eof) {
            std.debug.print(" at end", .{});
        } else if (token.type == .error_token) {
            // Nothing.
        } else {
            std.debug.print(" at '{s}'", .{token.start});
        }

        std.debug.print(": {s}\n", .{message});
        self.hadError = true;
    }
};

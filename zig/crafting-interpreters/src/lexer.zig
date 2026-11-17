const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;

pub const TokenKind = enum {
    paren_open,
    paren_close,
    /// A symbol like `+`, `foo`, `define`.
    symbol,
    /// A string literal like `"hello"`.
    string,
    /// A number literal like `123` or `3.14`.
    number,
    /// End of file.
    eof,
};

pub const Token = struct {
    kind: TokenKind,
    /// The slice of the source string that this token covers.
    text: []const u8,
    /// Line number where the token starts (1-indexed).
    line: usize,
};

pub const Lexer = struct {
    source: []const u8,
    /// Current character offset in `source`.
    current: usize,
    /// Current line number (1-indexed).
    line: usize,

    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .current = 0,
            .line = 1,
        };
    }

    pub fn nextToken(self: *Lexer) Token {
        self.skipWhitespace();

        if (self.isAtEnd()) {
            return self.makeToken(TokenKind.eof);
        }

        const c = self.peek();
        self.advance();

        return switch (c) {
            '(' => self.makeToken(TokenKind.paren_open),
            ')' => self.makeToken(TokenKind.paren_close),
            '"' => self.string(),
            '0'...'9' => self.number(),
            ';' => {
                while (self.peek() != '\n' and !self.isAtEnd()) {
                    self.advance();
                }
                return self.nextToken(); // Lex the next token after the comment
            },
            else => {
                if (self.isSymbolChar(c)) {
                    return self.symbol();
                }
                // For now, any other character is part of a symbol
                return self.symbol();
            },
        };
    }

    fn skipWhitespace(self: *Lexer) void {
        while (true) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    self.advance();
                },
                '\n' => {
                    self.line += 1;
                    self.advance();
                },
                else => return,
            }
        }
    }

    fn string(self: *Lexer) Token {
        const start = self.current - 1; // Starting from the '"'

        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            self.advance();
        }

        if (self.isAtEnd()) {
            // TODO: Error handling for unterminated string
            return Token{
                .kind = TokenKind.string, // Or an error token kind
                .text = self.source[start..self.current], // Include the unmatched '"' for debugging
                .line = self.line,
            };
        }

        self.advance(); // Consume the closing '"'
        return self.makeTokenAt(TokenKind.string, start, self.current);
    }

    fn number(self: *Lexer) Token {
        const start = self.current - 1; // Starting from the digit just consumed

        while (self.isDigit(self.peek())) {
            self.advance();
        }

        if (self.peek() == '.' and self.isDigit(self.peekNext())) {
            self.advance(); // Consume the '.'
            while (self.isDigit(self.peek())) {
                self.advance();
            }
        }

        return self.makeTokenAt(TokenKind.number, start, self.current);
    }

    fn symbol(self: *Lexer) Token {
        const start = self.current - 1; // Starting from the char just consumed

        while (self.isSymbolChar(self.peek()) and !self.isAtEnd()) {
            self.advance();
        }

        return self.makeTokenAt(TokenKind.symbol, start, self.current);
    }

    fn makeToken(self: *Lexer, kind: TokenKind) Token {
        return self.makeTokenAt(kind, self.current - 1, self.current);
    }

    fn makeTokenAt(self: *Lexer, kind: TokenKind, start: usize, end: usize) Token {
        return Token{
            .kind = kind,
            .text = self.source[start..end],
            .line = self.line,
        };
    }

    fn advance(self: *Lexer) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn peek(self: *Lexer) u8 {
        if (self.isAtEnd()) return 0; // null terminator
        return self.source[self.current];
    }

    fn peekNext(self: *Lexer) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn isDigit(self: *Lexer, c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAlpha(self: *Lexer, c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
    }

    fn isSymbolChar(self: *Lexer, c: u8) bool {
        return self.isAlpha(c) or self.isDigit(c) or
               c == '!' or c == '$' or c == '%' or c == '&' or c == '*' or
               c == '+' or c == '-' or c == '.' or c == '/' or c == ':' or
               c == '<' or c == '=' or c == '>' or c == '?' or c == '@' or
               c == '^' or c == '_' or c == '~';
    }
};

test "lexer basic" {
    const source = "(define x 10)";
    var lexer = Lexer.init(source);

    const tokens = [_]TokenKind{
        .paren_open, .symbol, .symbol, .number, .paren_close, .eof
    };

    for (tokens) |expected_kind| {
        const token = lexer.nextToken();
        std.debug.print("Token: {s} {any}\n", .{token.text, token.kind});
        try std.testing.expectEqual(expected_kind, token.kind);
    }
}

test "lexer string" {
    const source = "`(display \"hello world\")`";
    var lexer = Lexer.init(source);

    _ = lexer.nextToken(); // (
    _ = lexer.nextToken(); // display
    const string_token = lexer.nextToken(); // "hello world"

    std.debug.print("String token: {s}\n", .{string_token.text});
    try std.testing.expectEqual(TokenKind.string, string_token.kind);
    try std.testing.expectEqualStrings("`\"hello world\"`", string_token.text);
}

test "lexer number" {
    const source = "(+ 123 4.56)";
    var lexer = Lexer.init(source);

    _ = lexer.nextToken(); // (
    _ = lexer.nextToken(); // +
    const num1_token = lexer.nextToken(); // 123
    const num2_token = lexer.nextToken(); // 4.56

    try std.testing.expectEqual(TokenKind.number, num1_token.kind);
    try std.testing.expectEqualStrings("123", num1_token.text);
    try std.testing.expectEqual(TokenKind.number, num2_token.kind);
    try std.testing.expectEqualStrings("4.56", num2_token.text);
}

test "lexer comments" {
    const source = "; this is a comment\n(foo bar) ; another comment\n";
    var lexer = Lexer.init(source);

    const token1 = lexer.nextToken(); // (
    try std.testing.expectEqual(TokenKind.paren_open, token1.kind);
    try std.testing.expectEqualStrings("(", token1.text);
    try std.testing.expectEqual(2, token1.line);

    const token2 = lexer.nextToken(); // foo
    try std.testing.expectEqual(TokenKind.symbol, token2.kind);
    try std.testing.expectEqualStrings("foo", token2.text);
    try std.testing.expectEqual(2, token2.line);

    const token3 = lexer.nextToken(); // bar
    try std.testing.expectEqual(TokenKind.symbol, token3.kind);
    try std.testing.expectEqualStrings("bar", token3.text);
    try std.testing.expectEqual(2, token3.line);

    const token4 = lexer.nextToken(); // )
    try std.testing.expectEqual(TokenKind.paren_close, token4.kind);
    try std.testing.expectEqualStrings(")", token4.text);
    try std.testing.expectEqual(2, token4.line);

    const token5 = lexer.nextToken(); // EOF
    try std.testing.expectEqual(TokenKind.eof, token5.kind);
}

test "lexer complex expression" {
    const source = `(define (fact n)
  (if (= n 0)
      1
      (* n (fact (- n 1)))))`;
    var lexer = Lexer.init(source);

    const expected_tokens = [_]struct { kind: TokenKind, text: []const u8 }{
        { .kind = .paren_open, .text = "(" },
        { .kind = .symbol, .text = "define" },
        { .kind = .paren_open, .text = "(" },
        { .kind = .symbol, .text = "fact" },
        { .kind = .symbol, .text = "n" },
        { .kind = .paren_close, .text = ")" },
        { .kind = .paren_open, .text = "(" },
        { .kind = .symbol, .text = "if" },
        { .kind = .paren_open, .text = "(" },
        { .kind = .symbol, .text = "=" },
        { .kind = .symbol, .text = "n" },
        { .kind = .number, .text = "0" },
        { .kind = .paren_close, .text = ")" },
        { .kind = .number, .text = "1" },
        { .kind = .paren_open, .text = "(" },
        { .kind = .symbol, .text = "*" },
        { .kind = .symbol, .text = "n" },
        { .kind = .paren_open, .text = "(" },
        { .kind = .symbol, .text = "fact" },
        { .kind = .paren_open, .text = "(" },
        { .kind = .symbol, .text = "-" },
        { .kind = .symbol, .text = "n" },
        { .kind = .number, .text = "1" },
        { .kind = .paren_close, .text = ")" },
        { .kind = .paren_close, .text = ")" },
        { .kind = .paren_close, .text = ")" },
        { .kind = .paren_close, .text = ")" },
        { .kind = .eof, .text = "" },
    };

    for (expected_tokens) |expected| {
        const token = lexer.nextToken();
        std.debug.print("Expected: {s} {any}, Got: {s} {any}\n", .{expected.text, expected.kind, token.text, token.kind});
        try std.testing.expectEqual(expected.kind, token.kind);
        try std.testing.expectEqualStrings(expected.text, token.text);
    }
}

const std = @import("std");

pub const TokenType = enum {
    left_paren,
    right_paren,
    number,
    identifier,
    eof,
    error_token,
};

pub const Token = struct {
    type: TokenType,
    start: []const u8,
    line: usize,
};

pub const Scanner = struct {
    source: []const u8,
    start: usize,
    current: usize,
    line: usize,

    pub fn init(source: []const u8) Scanner {
        return Scanner{
            .source = source,
            .start = 0,
            .current = 0,
            .line = 1,
        };
    }

    pub fn scanToken(self: *Scanner) Token {
        self.skipWhitespace();
        self.start = self.current;

        if (self.isAtEnd()) return self.makeToken(.eof);

        const c = self.advance();

        if (isDigit(c)) return self.number();
        if (isAlpha(c)) return self.identifier();

        return switch (c) {
            '(' => self.makeToken(.left_paren),
            ')' => self.makeToken(.right_paren),
            '+', '-', '*', '/' => self.identifier(), // Treat operators as identifiers for now
            else => self.errorToken("Unexpected character."),
        };
    }

    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Scanner) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }

    fn peek(self: *Scanner) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *Scanner) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn skipWhitespace(self: *Scanner) void {
        while (true) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => _ = self.advance(),
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                ';' => {
                    while (self.peek() != '\n' and !self.isAtEnd()) _ = self.advance();
                },
                else => return,
            }
        }
    }

    fn number(self: *Scanner) Token {
        while (isDigit(self.peek())) _ = self.advance();

        // Look for a fractional part.
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            // Consume the "."
            _ = self.advance();

            while (isDigit(self.peek())) _ = self.advance();
        }

        return self.makeToken(.number);
    }

    fn identifier(self: *Scanner) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek()) or isSpecial(self.peek())) _ = self.advance();
        return self.makeToken(.identifier);
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAlpha(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }

    fn isSpecial(c: u8) bool {
        const special = "+-*/!@$%^&~=:<>?.";
        for (special) |s| {
            if (c == s) return true;
        }
        return false;
    }

    fn makeToken(self: *Scanner, tokenType: TokenType) Token {
        return Token{
            .type = tokenType,
            .start = self.source[self.start..self.current],
            .line = self.line,
        };
    }

    fn errorToken(self: *Scanner, message: []const u8) Token {
        return Token{
            .type = .error_token,
            .start = message,
            .line = self.line,
        };
    }
};

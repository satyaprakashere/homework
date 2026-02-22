const std = @import("std");

// Composition operator ∘: h ∘ (g₁, ..., gₘ) = f
// where f(x₁, ..., xₖ) = h(g₁(x₁, ..., xₖ), ..., gₘ(x₁, ..., xₖ))
fn compose(comptime h: anytype, comptime gs: anytype) type {
    // Validate that gs is a tuple of function pointers
    const gs_info = @typeInfo(@TypeOf(gs));
    if (gs_info != .@"struct") {
        @compileError("gs must be a tuple of function pointers");
    }

    // Get the number of functions in the tuple
    const num_gs = gs_info.@"struct".fields.len;
    // @compileLog("gs info: ", gs_info);

    // Get the parameter type of the first g function
    const g0_info = @typeInfo(@TypeOf(gs[0]));
    if (@typeInfo(g0_info.pointer.child) != .@"fn") {
        @compileError("gs must contain function pointers");
    }

    const g0_params = @typeInfo(g0_info.pointer.child).@"fn".params;
    if (g0_params.len != 1) {
        @compileError("g functions must have exactly one parameter");
    }

    const g0_param_type = g0_params[0].type.?;

    // Get the return type of h
    const h_info = @typeInfo(@TypeOf(h));
    if (h_info != .@"fn") {
        @compileError("h must be a function");
    }

    const h_params = h_info.@"fn".params;
    const h_return = h_info.@"fn".return_type.?;

    // Verify that the number of g functions matches h's parameters
    if (h_params.len != num_gs) {
        @compileError("h must have as many parameters as there are g functions");
    }

    // Verify that each g function returns a type compatible with h's parameters
    for (0..num_gs) |i| {
        const g_info = @typeInfo(@TypeOf(gs[i].*));
        if (g_info != .@"fn") {
            @compileError("gs must contain function pointers");
        }

        const g_return = g_info.@"fn".return_type.?;
        if (g_return != h_params[i].type.?) {
            @compileError("g functions must return types compatible with h's parameters");
        }
    }

    // Create the composed function type
    return struct {
        pub fn call(x: g0_param_type) h_return {
            comptime var args: [num_gs]type = undefined;
            inline for (gs, 0..) |g, i| {
                const g_info = @typeInfo(@TypeOf(g));
                const g_rtype = @typeInfo(g_info.pointer.child).@"fn".return_type;

                args[i] = g_rtype.?;
            }
            const argsT = buildTuple(&args);
            comptime var argsV: argsT = undefined;

            inline for (gs, 0..) |g, i| {
                const g_info = @typeInfo(@TypeOf(g));
                const g_rtype = @typeInfo(g_info.pointer.child).@"fn".return_type;

                const val = g.*(@as(g_rtype.?, x));
                argsV[i] = val;
            }

            // Call h with the results of g functions
            return @call(.auto, h, argsV);
        }
    };
}

fn buildTuple(comptime types: []const type) type {
    comptime var fields: [types.len]std.builtin.Type.StructField = undefined;
    const null_ptr: ?*const anyopaque = @ptrFromInt(0);
    inline for (types, 0..) |T, i| {
        fields[i] = .{
            .name = std.fmt.comptimePrint("{}", .{i}), // "@\"0\"", "@\"1\""
            .type = T,
            .default_value_ptr = null_ptr,
            .is_comptime = true,
            .alignment = 0,
        };
    }

    return @Type(.{ .@"struct" = .{ .layout = .auto, .fields = &fields, .decls = &[_]std.builtin.Type.Declaration{}, .is_tuple = true } });
}

// Example usage
fn add(x: i32, y: i32) i32 {
    return x + y;
}

fn double(x: i32) i32 {
    return x * 2;
}

fn square(x: i32) i32 {
    return x * x;
}

pub fn main() void {
    // Compose add with double and square using a tuple
    const gs = .{ &double, &square };
    const Composed = compose(add, gs);

    // Call the composed function
    const result = Composed.call(5); // add(double(5), square(5)) = add(10, 25) = 35
    std.debug.print("Result: {d}\n", .{result});
}

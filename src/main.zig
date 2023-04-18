const std = @import("std");
const print = std.debug.print;

const memorySize = 1024 * 1024; // 1 MiB

fn interpret(memory: []u8, comptime prog: []const u8) !void {
    const stdin = std.io.getStdIn().reader();
    comptime var ii: u32 = 0; // instruction index for codegen
    var ip: u32 = 0; // instruction pointer at runtime
    var dp: u32 = 0; // data pointer at runtime

    inline while (ii != prog.len) : (ii += 1) {
        const c = prog[ii];
        switch (c) {
            '>' => dp += 1,
            '<' => dp -= 1,
            '+' => memory[dp] += 1,
            '-' => memory[dp] -= 1,
            '.' => print("{}", .{memory[dp]}),
            ',' => memory[dp] = try stdin.readByte(),
            '[' => if (memory[dp] == 0) {
                var depth: u32 = 1;
                while (depth != 0) {
                    ip += 1;
                    const c0 = prog[ip];
                    if (c0 == '[') {
                        depth += 1;
                    } else if (c0 == ']') {
                        depth -= 1;
                    }
                }
            },
            ']' => if (memory[dp] != 0) {
                var depth: u32 = 1;
                while (depth != 0) {
                    ip -= 1;
                    const c0 = prog[ip];
                    if (c0 == ']') {
                        depth += 1;
                    } else if (c0 == '[') {
                        depth -= 1;
                    }
                }
            },
            else => unreachable,
        }
        ip += 1;
    }
}

fn fuck() !void {
    var memory = [_]u8{0} ** memorySize;
    memory[0] = 44;
    memory[1] = 42;
    print("adding {} and {}\n", .{ memory[0], memory[1] });

    // Adding memory[0] and memory[1] and store the result in memory[1]
    const prog = "[->+<]";
    try interpret(&memory, prog);

    // FIXME: we can't call `std.testing.expectEqual` at comptime since it in turn
    // calls `std.debug.print`, which acquires lock for `stderr`, which calls into
    // pthread, which is an external library, gg.
    try std.testing.expectEqual(memory[1], 86);
    print("result: {}\n", .{memory[1]});
}

fn Func(comptime factor: i32) type {
    return struct {
        inline fn process() void {
            print("once: {}\n", .{2 * factor});
        }
    };
}

fn Loop3Times(comptime func: fn () callconv(.Inline) void) type {
    return struct {
        inline fn execute_loop(counter: *u32) void {
            comptime var i = 0;
            inline while (i < 3) : (i += 1) {
                counter.* += 1;
                _ = func();
            }
        }
    };
}

fn StraightLineCodeEmitter(comptime prog: []const u8, comptime start_ii: u32) type {
    return struct {
        inline fn emit(memory: []u8, dp: *u32) void {
            const stdin = std.io.getStdIn().reader(); // FIXME: lock?
            comptime var ii: u32 = start_ii;
            inline while (ii < prog.len) : (ii += 1) {
                const inst = prog[ii];
                switch (inst) {
                    '>' => dp.* += 1,
                    '<' => dp.* -= 1,
                    '+' => memory[dp.*] += 1,
                    '-' => memory[dp.*] -= 1,
                    '.' => print("{s}", .{[1]u8{memory[0]}}),
                    ',' => memory[dp.*] = stdin.readByte() catch @panic("stdin.readByte() failed"),
                    '[' => {
                        LoopEmitter(prog, ii + 1).emit(memory, dp);

                        // now that we've emitted the loop body,
                        // set `ii` to `]` and continue emitting
                        // the straight line code afterwards.
                        // TODO: make this faster
                        comptime var depth: u32 = 1;
                        inline while (depth != 0) {
                            ii += 1;
                            const c0 = prog[ii];
                            if (c0 == '[') {
                                depth += 1;
                            } else if (c0 == ']') {
                                depth -= 1;
                            }
                        }
                        //@compileLog("ii: ", ii);
                    },
                    ']' => return, // FIXME: this is completely wrong and only for 1 level deep loop
                    else => @compileError("unknown instruction: `" ++ [1]u8{inst} ++ "`"),
                }
            }
        }
    };
}

fn LoopEmitter(comptime prog: []const u8, comptime start_ii: u32) type {
    return struct {
        inline fn emit(memory: []u8, dp: *u32) void {
            comptime var ii: u32 = start_ii;
            while (memory[dp.*] != 0) {
                StraightLineCodeEmitter(prog, ii).emit(memory, dp);
            }
        }
    };
}

pub fn main() !void {
    // try fuck();

    var memory = [_]u8{0} ** memorySize;
    memory[1] = 8;
    memory[0] = 4;
    var dp: u32 = 0; // data pointer
    // const prog = "[->+<]";
    //const prog = "+++.";
    const prog = "[->+<]";
    //const prog = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.";
    //const prog = "[-]";
    // const prog = "[-]";
    StraightLineCodeEmitter(prog, 0).emit(&memory, &dp);
    print("{}", .{memory[1]});
}

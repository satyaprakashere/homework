const std = @import("std");
const os = std.os;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var timer = try std.time.Timer.start();

    // Create a socketpair for local IPC (avoids network stack overhead)
    var fds: [2]os.fd_t = undefined;
    const domain = os.AF.UNIX;
    const type_t = os.SOCK.STREAM;
    const protocol: u32 = 0;
    // std.posix.socket(domain, type_t, protocol);
    try os.socketpair(domain, type_t, protocol, &fds);

    const msg = "Hello, world!";
    const msg_bytes = msg[0..];

    timer.reset();

    const sent = try os.send(fds[0], msg_bytes, 0);

    const elapsed_ns = timer.read();
    try stdout.print("send() sent {} bytes in {} ns\n", .{ sent, elapsed_ns });

    // Clean up
    _ = os.close(fds[0]);
    _ = os.close(fds[1]);
}

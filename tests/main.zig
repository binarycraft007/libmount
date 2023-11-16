const std = @import("std");
const c = @cImport(@cInclude("libmount.h"));
const testing = std.testing;

test "basic add functionality" {
    var ctx = c.mnt_new_context();
    try testing.expect(ctx != null);
    defer c.mnt_free_context(ctx);
    try std.fs.cwd().makeDir("mnt");
    defer std.fs.cwd().deleteDir("mnt") catch unreachable;
    var ret: c_int = 0;
    ret = c.mnt_context_set_source(ctx, "tests/testdata/test.ext4");
    try testing.expect(ret == 0);
    ret = c.mnt_context_set_target(ctx, "tests/mnt");
    try testing.expect(ret == 0);
    if (c.mnt_context_mount(ctx) == 0) {
        try testing.expect(c.mnt_context_umount(ctx) == 0);
    }
}

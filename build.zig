const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const s_path = b.option(
        []const u8,
        "fs-search-path",
        "fs search path",
    ) orelse "\"/sbin:/sbin/fs.d:/sbin/fs\"";
    const util_linux_dep = b.dependency("util_linux", .{});
    const include_path = util_linux_dep.path("include");
    const blkid_h_in = "libblkid/src/blkid.h.in";
    const blkid_h = b.addConfigHeader(.{
        .style = .{
            .cmake = util_linux_dep.path(blkid_h_in),
        },
        .include_path = "blkid.h",
    }, .{
        .LIBBLKID_VERSION = "1.1.0",
        .LIBBLKID_DATE = "17-Aug-2023",
    });
    const libmount_h_in = "libmount/src/libmount.h.in";
    const libmount_h = b.addConfigHeader(.{
        .style = .{
            .cmake = util_linux_dep.path(libmount_h_in),
        },
        .include_path = "libmount.h",
    }, .{
        .LIBMOUNT_VERSION = "2.39.2",
        .LIBMOUNT_MAJOR_VERSION = 2,
        .LIBMOUNT_MINOR_VERSION = 39,
        .LIBMOUNT_PATCH_VERSION = 2,
    });
    const libcommon = b.addStaticLibrary(.{
        .name = "common",
        .target = target,
        .optimize = optimize,
    });
    libcommon.linkLibC();
    inline for (common_src_files) |src| {
        libcommon.addCSourceFile(.{
            .file = util_linux_dep.path(src),
            .flags = &.{},
        });
    }
    if (libcommon.target_info.target.abi.isGnu()) {
        inline for (glibc_config) |config| {
            libcommon.defineCMacro(config, null);
        }
        inline for (glibc_src_files) |src| {
            libcommon.addCSourceFile(.{
                .file = util_linux_dep.path(src),
                .flags = &.{},
            });
        }
    }
    inline for (common_config) |config| {
        libcommon.defineCMacro(config, null);
    }
    libcommon.addConfigHeader(blkid_h);
    libcommon.addIncludePath(include_path);

    const libblkid = b.addStaticLibrary(.{
        .name = "blkid",
        .target = target,
        .optimize = optimize,
    });
    libblkid.linkLibC();
    libblkid.addConfigHeader(blkid_h);
    libblkid.defineCMacro("FS_SEARCH_PATH", s_path);
    libblkid.defineCMacro("LIBBLKID_VERSION", "\"1.1.0\"");
    libblkid.defineCMacro("LIBBLKID_DATE", "\"17-Aug-2023\"");
    if (libblkid.target_info.target.abi.isGnu()) {
        inline for (glibc_config) |config| {
            libblkid.defineCMacro(config, null);
        }
    }
    inline for (common_config) |config| {
        libblkid.defineCMacro(config, null);
    }
    inline for (blkid_src_files) |src| {
        libblkid.addCSourceFile(.{
            .file = util_linux_dep.path(src),
            .flags = &.{},
        });
    }
    libblkid.addIncludePath(util_linux_dep.path("libblkid/src"));
    libblkid.addIncludePath(include_path);
    libblkid.linkLibrary(libcommon);

    const libmount = b.addStaticLibrary(.{
        .name = "mount",
        .target = target,
        .optimize = optimize,
    });
    libmount.linkLibC();
    libmount.addConfigHeader(libmount_h);
    libmount.installConfigHeader(libmount_h, .{});
    libmount.addConfigHeader(blkid_h);
    libmount.defineCMacro("FS_SEARCH_PATH", s_path);
    if (libmount.target_info.target.abi.isGnu()) {
        inline for (glibc_config) |config| {
            libmount.defineCMacro(config, null);
        }
    }
    inline for (common_config) |config| {
        libmount.defineCMacro(config, null);
    }
    inline for (mount_src_files) |src| {
        libmount.addCSourceFile(.{
            .file = util_linux_dep.path(src),
            .flags = &.{},
        });
    }
    libmount.addIncludePath(util_linux_dep.path("libblkid/src"));
    libmount.addIncludePath(include_path);
    libmount.linkLibrary(libblkid);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "tests/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.linkLibrary(libmount);
    const run_main_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}

const common_src_files = [_][]const u8{
    "lib/blkdev.c",
    "lib/buffer.c",
    "lib/canonicalize.c",
    "lib/color-names.c",
    "lib/crc32.c",
    "lib/crc32c.c",
    "lib/crc64.c",
    "lib/c_strtod.c",
    "lib/encode.c",
    "lib/env.c",
    "lib/fileutils.c",
    "lib/idcache.c",
    "lib/jsonwrt.c",
    "lib/mangle.c",
    "lib/match.c",
    "lib/mbsalign.c",
    "lib/mbsedit.c",
    "lib/md5.c",
    "lib/procfs.c",
    "lib/pwdutils.c",
    "lib/randutils.c",
    "lib/sha1.c",
    "lib/sha256.c",
    "lib/signames.c",
    "lib/strutils.c",
    "lib/strv.c",
    "lib/timeutils.c",
    "lib/ttyutils.c",
    "lib/xxhash.c",
    "lib/sha1.c",
    "lib/strutils.c",
    "lib/strv.c",
    "lib/pager.c",
    "lib/sha1.c",
    "lib/strutils.c",

    "lib/monotonic.c",
    "lib/timer.c",
    "lib/swapprober.c",
    "lib/pty-session.c",
    "lib/ismounted.c",
    "lib/exec_shell.c",
    "lib/fileeq.c",
    "lib/logindefs.c",
    "lib/caputils.c",
    "lib/linux_version.c",
    "lib/loopdev.c",

    "lib/path.c",
    "lib/procfs.c",
    "lib/sysfs.c",
};

const glibc_src_files = [_][]const u8{
    "lib/cpuset.c",
};

const blkid_src_files = [_][]const u8{
    "libblkid/src/init.c",
    "libblkid/src/cache.c",
    "libblkid/src/config.c",
    "libblkid/src/dev.c",
    "libblkid/src/devname.c",
    "libblkid/src/devno.c",
    "libblkid/src/encode.c",
    "libblkid/src/evaluate.c",
    "libblkid/src/getsize.c",
    "libblkid/src/probe.c",
    "libblkid/src/read.c",
    "libblkid/src/resolve.c",
    "libblkid/src/save.c",
    "libblkid/src/tag.c",
    "libblkid/src/verify.c",
    "libblkid/src/version.c",

    "libblkid/src/partitions/aix.c",
    "libblkid/src/partitions/atari.c",
    "libblkid/src/partitions/bsd.c",
    "libblkid/src/partitions/dos.c",
    "libblkid/src/partitions/gpt.c",
    "libblkid/src/partitions/mac.c",
    "libblkid/src/partitions/minix.c",
    "libblkid/src/partitions/partitions.c",
    "libblkid/src/partitions/sgi.c",
    "libblkid/src/partitions/solaris_x86.c",
    "libblkid/src/partitions/sun.c",
    "libblkid/src/partitions/ultrix.c",
    "libblkid/src/partitions/unixware.c",

    "libblkid/src/superblocks/adaptec_raid.c",
    "libblkid/src/superblocks/apfs.c",
    "libblkid/src/superblocks/bcache.c",
    "libblkid/src/superblocks/befs.c",
    "libblkid/src/superblocks/bfs.c",
    "libblkid/src/superblocks/bitlocker.c",
    "libblkid/src/superblocks/bluestore.c",
    "libblkid/src/superblocks/btrfs.c",
    "libblkid/src/superblocks/cs_fvault2.c",
    "libblkid/src/superblocks/cramfs.c",
    "libblkid/src/superblocks/ddf_raid.c",
    "libblkid/src/superblocks/drbd.c",
    "libblkid/src/superblocks/drbdproxy_datalog.c",
    "libblkid/src/superblocks/drbdmanage.c",
    "libblkid/src/superblocks/exfat.c",
    "libblkid/src/superblocks/exfs.c",
    "libblkid/src/superblocks/ext.c",
    "libblkid/src/superblocks/f2fs.c",
    "libblkid/src/superblocks/gfs.c",
    "libblkid/src/superblocks/hfs.c",
    "libblkid/src/superblocks/highpoint_raid.c",
    "libblkid/src/superblocks/hpfs.c",
    "libblkid/src/superblocks/iso9660.c",
    "libblkid/src/superblocks/isw_raid.c",
    "libblkid/src/superblocks/jfs.c",
    "libblkid/src/superblocks/jmicron_raid.c",
    "libblkid/src/superblocks/linux_raid.c",
    "libblkid/src/superblocks/lsi_raid.c",
    "libblkid/src/superblocks/luks.c",
    "libblkid/src/superblocks/lvm.c",
    "libblkid/src/superblocks/minix.c",
    "libblkid/src/superblocks/mpool.c",
    "libblkid/src/superblocks/netware.c",
    "libblkid/src/superblocks/nilfs.c",
    "libblkid/src/superblocks/ntfs.c",
    "libblkid/src/superblocks/refs.c",
    "libblkid/src/superblocks/nvidia_raid.c",
    "libblkid/src/superblocks/ocfs.c",
    "libblkid/src/superblocks/promise_raid.c",
    "libblkid/src/superblocks/reiserfs.c",
    "libblkid/src/superblocks/romfs.c",
    "libblkid/src/superblocks/silicon_raid.c",
    "libblkid/src/superblocks/squashfs.c",
    "libblkid/src/superblocks/stratis.c",
    "libblkid/src/superblocks/superblocks.c",
    "libblkid/src/superblocks/swap.c",
    "libblkid/src/superblocks/sysv.c",
    "libblkid/src/superblocks/ubi.c",
    "libblkid/src/superblocks/ubifs.c",
    "libblkid/src/superblocks/udf.c",
    "libblkid/src/superblocks/ufs.c",
    "libblkid/src/superblocks/vdo.c",
    "libblkid/src/superblocks/vfat.c",
    "libblkid/src/superblocks/via_raid.c",
    "libblkid/src/superblocks/vmfs.c",
    "libblkid/src/superblocks/vxfs.c",
    "libblkid/src/superblocks/xfs.c",
    "libblkid/src/superblocks/zfs.c",
    "libblkid/src/superblocks/zonefs.c",
    "libblkid/src/superblocks/erofs.c",

    "libblkid/src/topology/topology.c",
    "libblkid/src/topology/dm.c",
    "libblkid/src/topology/evms.c",
    "libblkid/src/topology/ioctl.c",
    "libblkid/src/topology/lvm.c",
    "libblkid/src/topology/md.c",
    "libblkid/src/topology/sysfs.c",
};

const mount_src_files = [_][]const u8{
    "libmount/src/cache.c",
    "libmount/src/fs.c",
    "libmount/src/init.c",
    "libmount/src/iter.c",
    "libmount/src/lock.c",
    "libmount/src/optmap.c",
    "libmount/src/optstr.c",
    "libmount/src/tab.c",
    "libmount/src/tab_diff.c",
    "libmount/src/tab_parse.c",
    "libmount/src/tab_update.c",
    "libmount/src/test.c",
    "libmount/src/utils.c",
    "libmount/src/version.c",

    "libmount/src/hooks.c",
    "libmount/src/monitor.c",
    "libmount/src/optlist.c",
    "libmount/src/hook_veritydev.c",
    "libmount/src/hook_subdir.c",
    "libmount/src/hook_owner.c",
    "libmount/src/hook_mount.c",
    "libmount/src/hook_mount_legacy.c",
    "libmount/src/hook_mkdir.c",
    "libmount/src/hook_selinux.c",
    "libmount/src/hook_loopdev.c",
    "libmount/src/hook_idmap.c",
    "libmount/src/context_umount.c",
    "libmount/src/context_mount.c",
    "libmount/src/context.c",
    "libmount/src/btrfs.c",
};

const common_config = [_][]const u8{
    "_GNU_SOURCE",
    "HAVE_OPENAT",
    "HAVE_DIRFD",
    "HAVE_GETDTABLESIZE",
    "HAVE_GETRLIMIT ",
    "HAVE_SYSCONF ",
    "HAVE_UNSHARE",
    "HAVE_SETNS",
    "CLOCK_BOOTTIME",
    "HAVE_FSYNC",
    "HAVE_SMACK",
    "HAVE_BTRFS_SUPPORT",
    "HAVE_LINUX_NSFS_H",
    "HAVE_UTIMENSAT",
    "HAVE_EACCESS",
    "HAVE_SMACK",
    "HAVE_CRYPT_ACTIVATE_BY_SIGNED_KEY",
    "HAVE_WIDECHAR",
    "HAVE_ERR_H",
    "HAVE_SYS_SYSMACROS_H",
    "HAVE_NANOSLEEP",
    "HAVE_LINUX_VERSION_H",
    "HAVE_PATHS_H",
    "HAVE_SYS_SENDFILE_H",
    "HAVE_STDIO_EXT_H",
    "HAVE___FPENDING",
    "HAVE_WIDECHAR",
    "HAVE_LOCALE_H",
    "HAVE_LANGINFO_H",
    "HAVE_SYS_SYSCALL_H",
    "HAVE_TIMER_CREATE",
    "HAVE_SYS_STATFS_H",
    "HAVE_LINUX_BLKZONED_H",
    "HAVE_SRANDOM",
    "HAVE_SYS_IOCTL_H",
    "HAVE_SYS_TTYDEFAULTS_H",
    "HAVE_OPENAT",
    "HAVE_SYSINFO",
};

const glibc_config = [_][]const u8{
    "HAVE_CPU_SET_T",
    "HAVE_CLOSE_RANGE",
    "HAVE_CRYPTSETUP",
    "HAVE_SCANDIRAT",
};

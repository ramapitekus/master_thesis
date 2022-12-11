// Copyright 2019 the Go-FUSE Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package fs

import (
	"context"
	"sync"

	//	"time"

	"syscall"

	"github.com/hanwen/go-fuse/v2/fuse"
	"golang.org/x/sys/unix"
)

// NewLoopbackFile creates a FileHandle out of a file descriptor. All
// operations are implemented. When using the Fd from a *os.File, call
// syscall.Dup() on the Fd, to avoid os.File's finalizer from closing
// the file descriptor.
func NewLoopbackFile(Fd int) FileHandle {
	return &LoopbackFile{Fd: Fd}
}

type LoopbackFile struct {
	mu sync.Mutex
	Fd int
}

var _ = (FileHandle)((*LoopbackFile)(nil))
var _ = (FileReleaser)((*LoopbackFile)(nil))
var _ = (FileGetattrer)((*LoopbackFile)(nil))
var _ = (FileReader)((*LoopbackFile)(nil))
var _ = (FileWriter)((*LoopbackFile)(nil))
var _ = (FileGetlker)((*LoopbackFile)(nil))
var _ = (FileSetlker)((*LoopbackFile)(nil))
var _ = (FileSetlkwer)((*LoopbackFile)(nil))
var _ = (FileLseeker)((*LoopbackFile)(nil))
var _ = (FileFlusher)((*LoopbackFile)(nil))
var _ = (FileFsyncer)((*LoopbackFile)(nil))
var _ = (FileSetattrer)((*LoopbackFile)(nil))
var _ = (FileAllocater)((*LoopbackFile)(nil))

func (f *LoopbackFile) Read(ctx context.Context, buf []byte, off int64) (res fuse.ReadResult, errno syscall.Errno) {
	f.mu.Lock()
	defer f.mu.Unlock()
	r := fuse.ReadResultFd(uintptr(f.Fd), off, len(buf))
	return r, OK
}

func (f *LoopbackFile) Write(ctx context.Context, data []byte, off int64) (uint32, syscall.Errno) {
	f.mu.Lock()
	defer f.mu.Unlock()
	n, err := syscall.Pwrite(f.Fd, data, off)
	return uint32(n), ToErrno(err)
}

func (f *LoopbackFile) Release(ctx context.Context) syscall.Errno {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.Fd != -1 {
		err := syscall.Close(f.Fd)
		f.Fd = -1
		return ToErrno(err)
	}
	return syscall.EBADF
}

func (f *LoopbackFile) Flush(ctx context.Context) syscall.Errno {
	f.mu.Lock()
	defer f.mu.Unlock()
	// Since Flush() may be called for each dup'd Fd, we don't
	// want to really close the file, we just want to flush. This
	// is achieved by closing a dup'd Fd.
	newFd, err := syscall.Dup(f.Fd)

	if err != nil {
		return ToErrno(err)
	}
	err = syscall.Close(newFd)
	return ToErrno(err)
}

func (f *LoopbackFile) Fsync(ctx context.Context, flags uint32) (errno syscall.Errno) {
	f.mu.Lock()
	defer f.mu.Unlock()
	r := ToErrno(syscall.Fsync(f.Fd))

	return r
}

const (
	_OFD_GETLK  = 36
	_OFD_SETLK  = 37
	_OFD_SETLKW = 38
)

func (f *LoopbackFile) Getlk(ctx context.Context, owner uint64, lk *fuse.FileLock, flags uint32, out *fuse.FileLock) (errno syscall.Errno) {
	f.mu.Lock()
	defer f.mu.Unlock()
	flk := syscall.Flock_t{}
	lk.ToFlockT(&flk)
	errno = ToErrno(syscall.FcntlFlock(uintptr(f.Fd), _OFD_GETLK, &flk))
	out.FromFlockT(&flk)
	return
}

func (f *LoopbackFile) Setlk(ctx context.Context, owner uint64, lk *fuse.FileLock, flags uint32) (errno syscall.Errno) {
	return f.setLock(ctx, owner, lk, flags, false)
}

func (f *LoopbackFile) Setlkw(ctx context.Context, owner uint64, lk *fuse.FileLock, flags uint32) (errno syscall.Errno) {
	return f.setLock(ctx, owner, lk, flags, true)
}

func (f *LoopbackFile) setLock(ctx context.Context, owner uint64, lk *fuse.FileLock, flags uint32, blocking bool) (errno syscall.Errno) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if (flags & fuse.FUSE_LK_FLOCK) != 0 {
		var op int
		switch lk.Typ {
		case syscall.F_RDLCK:
			op = syscall.LOCK_SH
		case syscall.F_WRLCK:
			op = syscall.LOCK_EX
		case syscall.F_UNLCK:
			op = syscall.LOCK_UN
		default:
			return syscall.EINVAL
		}
		if !blocking {
			op |= syscall.LOCK_NB
		}
		return ToErrno(syscall.Flock(f.Fd, op))
	} else {
		flk := syscall.Flock_t{}
		lk.ToFlockT(&flk)
		var op int
		if blocking {
			op = _OFD_SETLKW
		} else {
			op = _OFD_SETLK
		}
		return ToErrno(syscall.FcntlFlock(uintptr(f.Fd), op, &flk))
	}
}

func (f *LoopbackFile) Setattr(ctx context.Context, in *fuse.SetAttrIn, out *fuse.AttrOut) syscall.Errno {
	if errno := f.setAttr(ctx, in); errno != 0 {
		return errno
	}

	return f.Getattr(ctx, out)
}

func (f *LoopbackFile) setAttr(ctx context.Context, in *fuse.SetAttrIn) syscall.Errno {
	f.mu.Lock()
	defer f.mu.Unlock()
	var errno syscall.Errno
	if mode, ok := in.GetMode(); ok {
		errno = ToErrno(syscall.Fchmod(f.Fd, mode))
		if errno != 0 {
			return errno
		}
	}

	uid32, uOk := in.GetUID()
	gid32, gOk := in.GetGID()
	if uOk || gOk {
		uid := -1
		gid := -1

		if uOk {
			uid = int(uid32)
		}
		if gOk {
			gid = int(gid32)
		}
		errno = ToErrno(syscall.Fchown(f.Fd, uid, gid))
		if errno != 0 {
			return errno
		}
	}

	mtime, mok := in.GetMTime()
	atime, aok := in.GetATime()

	if mok || aok {
		ap := &atime
		mp := &mtime
		if !aok {
			ap = nil
		}
		if !mok {
			mp = nil
		}
		errno = f.utimens(ap, mp)
		if errno != 0 {
			return errno
		}
	}

	if sz, ok := in.GetSize(); ok {
		errno = ToErrno(syscall.Ftruncate(f.Fd, int64(sz)))
		if errno != 0 {
			return errno
		}
	}
	return OK
}

func (f *LoopbackFile) Getattr(ctx context.Context, a *fuse.AttrOut) syscall.Errno {
	f.mu.Lock()
	defer f.mu.Unlock()
	st := syscall.Stat_t{}
	err := syscall.Fstat(f.Fd, &st)
	if err != nil {
		return ToErrno(err)
	}
	a.FromStat(&st)

	return OK
}

func (f *LoopbackFile) Lseek(ctx context.Context, off uint64, whence uint32) (uint64, syscall.Errno) {
	f.mu.Lock()
	defer f.mu.Unlock()
	n, err := unix.Seek(f.Fd, int64(off), int(whence))
	return uint64(n), ToErrno(err)
}

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"syscall"
	"time"

	"github.com/hanwen/go-fuse/v2/fs"
)

type RenameNode struct {
	fs.LoopbackNode

	Name string
}

type RenameFile struct {
	fs.LoopbackFile
	mu         sync.Mutex
	name       string
	node       *fs.LoopbackNode
	parentNode *fs.Inode
}

func NewLoopbackFile(fd int, name string, node *fs.LoopbackNode) fs.FileHandle {
	_, parentNode := node.Parent()
	return &RenameFile{

		LoopbackFile: fs.LoopbackFile{
			Fd: fd,
		},
		name:       name,
		node:       node,
		parentNode: parentNode,
	}
}

var _ = (fs.NodeOpener)((*RenameNode)(nil))
var _ = (fs.FileReader)((*RenameFile)(nil))
var _ = (fs.FileWriter)((*RenameFile)(nil))

func (f *RenameFile) Write(ctx context.Context, data []byte, off int64) (uint32, syscall.Errno) {
	f.mu.Lock()
	defer f.mu.Unlock()
	var slice []byte
	n, err := syscall.Pwrite(f.Fd, slice, off)
	return uint32(n), fs.ToErrno(err)
}

func newRenameNode(rootData *fs.LoopbackRoot, _ *fs.Inode, name string, _ *syscall.Stat_t) fs.InodeEmbedder {
	n := &RenameNode{
		LoopbackNode: fs.LoopbackNode{
			RootData: rootData,
		},
		Name: name,
	}
	return n
}

func (n *RenameNode) Open(ctx context.Context, flags uint32) (fh fs.FileHandle, fuseFlags uint32, errno syscall.Errno) {
	flags = flags &^ syscall.O_APPEND
	rootPath := n.Path(n.Root())
	path := filepath.Join(n.RootData.Path, rootPath)
	f, err := syscall.Open(path, int(flags), 0)
	if err != nil {
		return nil, 0, fs.ToErrno(err)
	}
	lf := NewLoopbackFile(f, n.Name, &n.LoopbackNode)
	return lf, 0, 0
}

func main() {
	path := os.Getenv("HOME") + "/Desktop"
	rootData := &fs.LoopbackRoot{
		NewNode: newRenameNode,
		Path:    "./",
	}

	sec := time.Second
	opts := &fs.Options{
		AttrTimeout:  &sec,
		EntryTimeout: &sec,
	}

	opts.MountOptions.Options = append(opts.MountOptions.Options, "fsname=renameFS")
	opts.MountOptions.Name = "renameFS"
	opts.NullPermissions = true

	server, err := fs.Mount(path, newRenameNode(rootData, nil, "root", nil), opts)
	if err != nil {
		log.Fatalf("Mount fail: %v\n", err)
	}
	fmt.Println("Mounted!")
	server.Wait()
}

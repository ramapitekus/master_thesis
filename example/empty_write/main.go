package main

import (
	"context"
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/hanwen/go-fuse/v2/fs"
	"github.com/hanwen/go-fuse/v2/fuse"
)

type RenameNode struct {
	fs.LoopbackNode

	Name string
}

type Status int32

type JsonDump struct {
	Pid     uint32
	Entropy string
	Op      string
	Ext     string
	Time    string
}
func (m JsonDump) String() string {
    return fmt.Sprintf("%d,%f,'%s','%s','%s'", m.Pid, m.Entropy, m.Op, m.Ext, m.Time)
}

type JsonRecords struct {
	JsonDumps []JsonDump `json:"Ops"`
}

type RenameFile struct {
	fs.LoopbackFile
	mu         sync.Mutex
	name       string
	node       *fs.LoopbackNode
	parentNode *fs.Inode
}


//func DumpOpToJson(ctx context.Context, jsonDump JsonDump) {
//	var jsonRecords JsonRecords
//
//	//ff, _ := os.OpenFile("test.json", os.O_CREATE|os.O_WRONLY, 0644)
//	//bytes, _ := os.ReadFile("test.json")
//	//json.Unmarshal(bytes, &jsonRecords)
//
//	// jsonRecords.JsonDumps = append(jsonRecords.JsonDumps, jsonDump)
//	// file, _ := json.Marshal(jsonRecords)
//
//	//ff.Write([]byte(file))
//}

func setLogFile(num int) {
	file, err := os.OpenFile(fmt.Sprintf("logfile%d.csv", num), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		log.Fatal(err)
	}
	log.SetFlags(0)
	log.SetOutput(file)
	log.Println("Pid,Entropy,Op,Ext,Time")
}

func changeLogFile(){
	setLogFile(0)
	interval := time.Duration(20) * time.Second
	ticker := time.NewTicker(interval)
	numLog := 1
	for range ticker.C {
		setLogFile(numLog)
		numLog++
}
}

func isMalicious() bool {
	classifier, err := os.ReadFile("classifier.log")
	if err != nil {
		fmt.Println(err)
	}
	classifierBool, _ := strconv.ParseBool(string(classifier))
	return classifierBool
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
	caller, _ := fuse.FromContext(ctx)
	pid := caller.Pid
	ext := strings.Split(f.name, ".")[1]
	entropy := GetEntropy(data)
	dt := time.Now().String()

	jsonDump := JsonDump{
		Pid:     pid,
		Entropy: entropy,
		Op:      "write",
		Ext:     ext,
		Time:	 dt,
	}

	log.Println(jsonDump)

	defer f.mu.Unlock()
	if isMalicious() == true {
		// var empty []byte
		// bytesRead, _ := os.ReadFile(f.name)
		// n, err := syscall.Pwrite(f.Fd, bytesRead, off)
		return uint32(40), 0
	} else {
		n, err := syscall.Pwrite(f.Fd, data, off)
		return uint32(n), fs.ToErrno(err)
	}
}

func (f *RenameFile) Read(ctx context.Context, buf []byte, off int64) (res fuse.ReadResult, errno syscall.Errno) {
	f.mu.Lock()
	defer f.mu.Unlock()
	caller, _ := fuse.FromContext(ctx)
	pid := caller.Pid
	ext := strings.Split(f.name, ".")[1]
	dt := time.Now().String()

	jsonDump := JsonDump{
		Pid:     pid,
		Entropy: "null",
		Op:      "read",
		Ext:     ext,
		Time:	 dt,
	}

	log.Println(jsonDump)

	r := fuse.ReadResultFd(uintptr(f.Fd), off, len(buf))
	return r, fs.OK
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

func (n *RenameNode) path() string {
	path := n.Path(n.Root())
	return filepath.Join(n.RootData.Path, path)
}

//func (n *RenameNode) Readdir(ctx context.Context) (fs.DirStream, syscall.Errno) {
//	caller, _ := fuse.FromContext(ctx)
//	pid := caller.Pid
//	dt := time.Now().String()
//	fmt.Println("Current date and time is: ", dt)
//	//jsonDump := JsonDump{
//	//	Pid:     pid,
//	//	Entropy: nil,
//	//	Op:      "listDir",
//	//	Ext:     nil,
//	//	Time:    dt,
//	//}
//	//DumpOpToJson(ctx, jsonDump)
//
//	return fs.NewLoopbackDirStream(n.path())
//}

func main() {
	go changeLogFile()

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

func GetEntropy(data []byte) (entr float64) {
	possible := make(map[string]int)

	for i := 1; i <= 256; i++ {
		possible[string(i)] = 0
	}

	for _, byt := range data {
		possible[string(byt)] += 1
	}

	var data_len = len(data)
	var entropy = 0.0

	for char := range possible {
		if possible[char] == 0 {
			continue
		}
		var p = float64(possible[char]) / float64(data_len)
		entropy -= p * math.Log2(p)
	}
	return entropy
}

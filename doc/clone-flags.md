# Linux clone() Flags Reference

The `clone()` system call allows fine-grained control over what resources are shared between parent and child processes. This document describes the most important flags and their interactions.

## Core Resource Sharing Flags

### CLONE_VM (0x00000100)
- **Effect**: Parent and child share the same virtual memory space
- **Without**: Child gets copy-on-write pages (like fork)
- **Use case**: Essential for threads that need to share data
- **Note**: Memory modifications by either process are immediately visible to the other

### CLONE_FILES (0x00000400)
- **Effect**: Parent and child share the file descriptor table
- **Without**: Child gets a duplicate of the parent's FD table
- **Use case**: When threads need to coordinate file operations
- **Note**: open(), close(), dup() in one process affects the other

### CLONE_SIGHAND (0x00000800)
- **Effect**: Parent and child share signal handler table
- **Without**: Child inherits a copy of signal handlers
- **Requires**: CLONE_VM (since Linux 2.6.0)
- **Note**: sigaction() changes affect both processes, but signal masks remain separate

### CLONE_THREAD (0x00010000)
- **Effect**: Child is placed in same thread group as parent
- **Result**: Same PID (TGID), different TID
- **Requires**: CLONE_SIGHAND (which requires CLONE_VM)
- **Important**: No SIGCHLD on exit; parent can't wait() for child
- **Use case**: POSIX threads implementation

## Additional Sharing Flags

### CLONE_FS (0x00000200)
- **Effect**: Share filesystem information (root, cwd, umask)
- **Note**: chdir(), chroot(), umask() affect both processes

### CLONE_SYSVSEM (0x00040000)
- **Effect**: Share System V semaphore undo values
- **Use case**: Threads that use SysV semaphores

### CLONE_IO (0x80000000)
- **Effect**: Share I/O context (I/O scheduler attributes)
- **Since**: Linux 2.6.25

## Process Relationship Flags

### CLONE_PARENT (0x00008000)
- **Effect**: Child has same parent as caller (siblings, not parent-child)
- **Note**: getppid() returns same value for both

### CLONE_NEWNS (0x00020000)
- **Effect**: Child starts in new mount namespace
- **Use case**: Container implementations

## Thread Management Flags

### CLONE_SETTLS (0x00080000)
- **Effect**: Set Thread Local Storage descriptor
- **Use case**: Threading libraries need this for thread-local variables

### CLONE_PARENT_SETTID (0x00100000)
- **Effect**: Store child TID in parent's memory
- **Use case**: Parent needs to know child's TID immediately

### CLONE_CHILD_CLEARTID (0x00200000)
- **Effect**: Clear TID in child's memory on exit and wake futex
- **Use case**: Efficient thread join implementation

### CLONE_CHILD_SETTID (0x01000000)
- **Effect**: Store child TID in child's memory
- **Use case**: Child needs to know its own TID

## Signal Behavior

### CLONE_VFORK (0x00004000)
- **Effect**: Parent suspended until child exits or execs
- **Use case**: Efficient vfork() implementation

### CLONE_UNTRACED (0x00800000)
- **Effect**: Tracing process can't force CLONE_PTRACE
- **Since**: Linux 2.5.46

## Flag Dependencies

The kernel enforces these relationships:
```
CLONE_THREAD → requires CLONE_SIGHAND → requires CLONE_VM
```

## Common Flag Combinations

### pthread_create() typically uses:
```c
CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD |
CLONE_SYSVSEM | CLONE_SETTLS | CLONE_PARENT_SETTID | CLONE_CHILD_CLEARTID
```

### fork() essentially uses:
```c
SIGCHLD | CLONE_CHILD_CLEARTID | CLONE_CHILD_SETTID
```

### vfork() uses:
```c
CLONE_VFORK | CLONE_VM | SIGCHLD
```

### Simple thread (shares memory only):
```c
CLONE_VM | SIGCHLD
```
- Shares memory but has separate PID
- Parent can wait() for it
- Good for simple parallelism without full POSIX semantics

## Exit Behavior

Without CLONE_THREAD:
- Child sends SIGCHLD (or other termination signal) to parent
- Parent can wait()/waitpid() for child
- Child process appears in process listing with its own PID

With CLONE_THREAD:
- No signal sent to parent on exit
- Parent cannot wait() for child
- All threads share same PID (different TIDs)
- Threads must coordinate their own cleanup

## Security Considerations

Some flags require CAP_SYS_ADMIN:
- CLONE_NEWNS (new mount namespace)
- CLONE_NEWUTS (new UTS namespace)
- CLONE_NEWIPC (new IPC namespace)
- CLONE_NEWPID (new PID namespace)
- CLONE_NEWNET (new network namespace)
- CLONE_NEWUSER (new user namespace - special rules)

## Example Usage in Assembly

```asm
;; Simple thread with shared memory
mov rdi, CLONE_VM | SIGCHLD    ; Share memory, get exit signal
mov rsi, rsp                    ; Stack pointer for child
mov rax, SYS_clone
syscall

;; Full POSIX thread
mov rdi, CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD
or  rdi, CLONE_SETTLS | CLONE_PARENT_SETTID | CLONE_CHILD_CLEARTID
mov rsi, child_stack_top
mov rax, SYS_clone
syscall
```
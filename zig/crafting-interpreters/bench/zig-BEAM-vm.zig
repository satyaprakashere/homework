// https://claude.ai/chat/cedd3660-ee18-41f2-a965-27472a4eac38

const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const HashMap = std.HashMap;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;
const Mutex = std.Thread.Mutex;
const Condition = std.Thread.Condition;
const Atomic = std.atomic.Atomic;

// ===== ERROR HANDLING =====
const VMError = error{
    OutOfMemory,
    ProcessNotFound,
    InvalidInstruction,
    StackUnderflow,
    InvalidType,
    MessageQueueFull,
    ProcessDead,
    NoSuchFunction,
    BadArity,
    SystemLimit,
    NetworkError,
    FileError,
    TimeoutError,
};

// ===== MEMORY MANAGEMENT =====
const GCObjectType = enum {
    tuple,
    list,
    binary,
    map,
    function,
};

const GCObject = struct {
    obj_type: GCObjectType,
    size: usize,
    marked: bool,
    next: ?*GCObject,
    data: []u8,
    
    const Self = @This();
    
    pub fn init(allocator: Allocator, obj_type: GCObjectType, size: usize) !*Self {
        const obj = try allocator.create(Self);
        obj.* = Self{
            .obj_type = obj_type,
            .size = size,
            .marked = false,
            .next = null,
            .data = try allocator.alloc(u8, size),
        };
        return obj;
    }
    
    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.free(self.data);
        allocator.destroy(self);
    }
};

const GarbageCollector = struct {
    allocator: Allocator,
    objects: ?*GCObject,
    bytes_allocated: usize,
    next_gc: usize,
    mutex: Mutex,
    
    const Self = @This();
    const GC_HEAP_GROW_FACTOR = 2;
    const INITIAL_GC_THRESHOLD = 1024 * 1024; // 1MB
    
    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .objects = null,
            .bytes_allocated = 0,
            .next_gc = INITIAL_GC_THRESHOLD,
            .mutex = Mutex{},
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        var current = self.objects;
        while (current) |obj| {
            const next = obj.next;
            obj.deinit(self.allocator);
            current = next;
        }
    }
    
    pub fn allocate_object(self: *Self, obj_type: GCObjectType, size: usize) !*GCObject {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        const obj = try GCObject.init(self.allocator, obj_type, size);
        obj.next = self.objects;
        self.objects = obj;
        
        self.bytes_allocated += size;
        
        if (self.bytes_allocated > self.next_gc) {
            // Trigger GC in background
            _ = try Thread.spawn(.{}, collect_garbage_async, .{self});
        }
        
        return obj;
    }
    
    fn collect_garbage_async(self: *Self) void {
        self.collect_garbage() catch |err| {
            print("GC error: {}\n", .{err});
        };
    }
    
    pub fn collect_garbage(self: *Self) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        // Mark phase - would mark all reachable objects from roots
        self.mark_all_objects();
        
        // Sweep phase
        var prev: ?*GCObject = null;
        var current = self.objects;
        
        while (current) |obj| {
            if (obj.marked) {
                obj.marked = false; // Reset for next GC
                prev = obj;
                current = obj.next;
            } else {
                // Unreachable object, free it
                if (prev) |p| {
                    p.next = obj.next;
                } else {
                    self.objects = obj.next;
                }
                
                const next = obj.next;
                self.bytes_allocated -= obj.size;
                obj.deinit(self.allocator);
                current = next;
            }
        }
        
        self.next_gc = self.bytes_allocated * GC_HEAP_GROW_FACTOR;
        print("GC completed. Heap size: {} bytes\n", .{self.bytes_allocated});
    }
    
    fn mark_all_objects(self: *Self) void {
        // In a real implementation, this would traverse all process stacks,
        // registers, and other roots to mark reachable objects
        var current = self.objects;
        while (current) |obj| {
            obj.marked = true; // Simplified - mark all for now
            current = obj.next;
        }
    }
};

// ===== TERM SYSTEM =====
const TermType = enum(u8) {
    small_integer,
    big_integer,
    float,
    atom,
    reference,
    port,
    pid,
    tuple,
    map,
    nil,
    list,
    binary,
    function,
    external_function,
};

const Term = packed struct {
    tag: TermType,
    data: union {
        small_int: i32,
        big_int: *i64,
        float: f64,
        atom: u32, // Atom table index
        reference: u64,
        port: u32,
        pid: ProcessId,
        tuple: *TupleData,
        map: *MapData,
        list: *ListData,
        binary: *BinaryData,
        function: *FunctionData,
        external_function: *ExternalFunctionData,
    },
    
    const Self = @This();
    
    pub fn make_integer(value: i32) Self {
        return Self{
            .tag = .small_integer,
            .data = .{ .small_int = value },
        };
    }
    
    pub fn make_atom(atom_id: u32) Self {
        return Self{
            .tag = .atom,
            .data = .{ .atom = atom_id },
        };
    }
    
    pub fn make_pid(pid: ProcessId) Self {
        return Self{
            .tag = .pid,
            .data = .{ .pid = pid },
        };
    }
    
    pub fn make_nil() Self {
        return Self{
            .tag = .nil,
            .data = undefined,
        };
    }
    
    pub fn is_number(self: Self) bool {
        return self.tag == .small_integer or self.tag == .big_integer or self.tag == .float;
    }
    
    pub fn is_atom(self: Self) bool {
        return self.tag == .atom;
    }
    
    pub fn is_pid(self: Self) bool {
        return self.tag == .pid;
    }
};

const TupleData = struct {
    arity: u32,
    elements: []Term,
};

const MapData = struct {
    size: u32,
    pairs: []KeyValuePair,
};

const KeyValuePair = struct {
    key: Term,
    value: Term,
};

const ListData = struct {
    head: Term,
    tail: Term,
};

const BinaryData = struct {
    size: usize,
    data: []u8,
};

const FunctionData = struct {
    module: u32,
    function: u32,
    arity: u8,
    code: []Instruction,
};

const ExternalFunctionData = struct {
    module: u32,
    function: u32,
    arity: u8,
    native_func: *const fn ([]Term) VMError!Term,
};

// ===== ATOM TABLE =====
const AtomTable = struct {
    atoms: ArrayList([]const u8),
    atom_map: HashMap([]const u8, u32, std.hash_map.StringContext, std.hash_map.default_max_load_percentage),
    mutex: Mutex,
    
    const Self = @This();
    
    pub fn init(allocator: Allocator) Self {
        return Self{
            .atoms = ArrayList([]const u8).init(allocator),
            .atom_map = HashMap([]const u8, u32, std.hash_map.StringContext, std.hash_map.default_max_load_percentage).init(allocator),
            .mutex = Mutex{},
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.atoms.deinit();
        self.atom_map.deinit();
    }
    
    pub fn intern(self: *Self, name: []const u8) !u32 {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        if (self.atom_map.get(name)) |id| {
            return id;
        }
        
        const id = @as(u32, @intCast(self.atoms.items.len));
        try self.atoms.append(name);
        try self.atom_map.put(name, id);
        return id;
    }
    
    pub fn get_name(self: *Self, id: u32) ?[]const u8 {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        if (id < self.atoms.items.len) {
            return self.atoms.items[id];
        }
        return null;
    }
};

// ===== INSTRUCTION SET =====
const OpCode = enum(u8) {
    // Stack operations
    push_literal,
    push_var,
    pop,
    dup,
    swap,
    
    // Arithmetic
    add,
    sub,
    mul,
    div_int,
    div_float,
    rem,
    band,
    bor,
    bxor,
    bnot,
    bsl,
    bsr,
    
    // Comparison
    eq,
    ne,
    lt,
    le,
    gt,
    ge,
    
    // Type tests
    is_atom,
    is_number,
    is_tuple,
    is_list,
    is_binary,
    is_function,
    is_pid,
    
    // Control flow
    jump,
    jump_if_true,
    jump_if_false,
    call,
    call_ext,
    ret,
    try_case,
    catch_end,
    
    // Process operations
    spawn,
    spawn_link,
    spawn_monitor,
    send,
    receive,
    receive_timeout,
    link,
    unlink,
    monitor,
    demonitor,
    exit,
    
    // Tuple operations
    make_tuple,
    get_tuple_element,
    set_tuple_element,
    
    // List operations
    make_list,
    get_list_head,
    get_list_tail,
    
    // Map operations
    make_map,
    get_map_value,
    put_map_value,
    
    // Binary operations
    make_binary,
    binary_part,
    
    // Exception handling
    throw,
    err,

    // System operations
    apply,
    apply_last,
    gc,
    nif_start,
    nif_return,
    
    halt,
    nop,
};

const Instruction = struct {
    opcode: OpCode,
    args: [3]u32,
    
    const Self = @This();
    
    pub fn make(opcode: OpCode) Self {
        return Self{
            .opcode = opcode,
            .args = [_]u32{0} ** 3,
        };
    }
    
    pub fn make1(opcode: OpCode, arg1: u32) Self {
        return Self{
            .opcode = opcode,
            .args = [_]u32{ arg1, 0, 0 },
        };
    }
    
    pub fn make2(opcode: OpCode, arg1: u32, arg2: u32) Self {
        return Self{
            .opcode = opcode,
            .args = [_]u32{ arg1, arg2, 0 },
        };
    }
    
    pub fn make3(opcode: OpCode, arg1: u32, arg2: u32, arg3: u32) Self {
        return Self{
            .opcode = opcode,
            .args = [_]u32{ arg1, arg2, arg3 },
        };
    }
};

// ===== MESSAGE SYSTEM =====
const ProcessId = u64;

const MessageType = enum {
    normal,
    exit,
    system,
    monitor,
};

const Message = struct {
    msg_type: MessageType,
    from: ProcessId,
    to: ProcessId,
    data: Term,
    timestamp: i64,
    ref: ?u64,
    
    const Self = @This();
    
    pub fn normal_message(from: ProcessId, to: ProcessId, data: Term) Self {
        return Self{
            .msg_type = .normal,
            .from = from,
            .to = to,
            .data = data,
            .timestamp = std.time.milliTimestamp(),
            .ref = null,
        };
    }
    
    pub fn exit_message(from: ProcessId, to: ProcessId, reason: Term) Self {
        return Self{
            .msg_type = .exit,
            .from = from,
            .to = to,
            .data = reason,
            .timestamp = std.time.milliTimestamp(),
            .ref = null,
        };
    }
};

const MessageQueue = struct {
    messages: ArrayList(Message),
    mutex: Mutex,
    condition: Condition,
    max_size: usize,
    
    const Self = @This();
    const DEFAULT_MAX_SIZE = 10000;
    
    pub fn init(allocator: Allocator) Self {
        return Self{
            .messages = ArrayList(Message).init(allocator),
            .mutex = Mutex{},
            .condition = Condition{},
            .max_size = DEFAULT_MAX_SIZE,
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.messages.deinit();
    }
    
    pub fn send(self: *Self, message: Message) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        if (self.messages.items.len >= self.max_size) {
            return VMError.MessageQueueFull;
        }
        
        try self.messages.append(message);
        self.condition.signal();
    }
    
    pub fn receive(self: *Self) ?Message {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        if (self.messages.items.len > 0) {
            return self.messages.orderedRemove(0);
        }
        return null;
    }
    
    pub fn receive_timeout(self: *Self, timeout_ms: u64) ?Message {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        if (self.messages.items.len > 0) {
            return self.messages.orderedRemove(0);
        }
        
        // Wait for message with timeout
        const timeout_ns = timeout_ms * std.time.ns_per_ms;
        self.condition.timedWait(&self.mutex, timeout_ns) catch {};
        
        if (self.messages.items.len > 0) {
            return self.messages.orderedRemove(0);
        }
        return null;
    }
    
    pub fn has_messages(self: *Self) bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.messages.items.len > 0;
    }
};

// ===== PROCESS SYSTEM =====
const ProcessState = enum {
    embryo,
    runnable,
    running,
    waiting,
    suspended,
    exiting,
    dead,
};

const ProcessFlags = packed struct {
    trap_exit: bool = false,
    linked: bool = false,
    monitored: bool = false,
    system_process: bool = false,
    priority: u4 = 0,
    _padding: u3 = 0,
};

const ExitReason = enum {
    normal,
    killed,
    err,
    throw,
    exit,
};

const ProcessInfo = struct {
    id: ProcessId,
    parent: ?ProcessId,
    group_leader: ProcessId,
    flags: ProcessFlags,
    state: ProcessState,
    exit_reason: ExitReason,
    heap_size: usize,
    stack_size: usize,
    message_queue_len: usize,
    reductions: u64,
    created_at: i64,
    links: ArrayList(ProcessId),
    monitors: ArrayList(ProcessId),
    
    const Self = @This();
    
    pub fn init(allocator: Allocator, id: ProcessId, parent: ?ProcessId) Self {
        return Self{
            .id = id,
            .parent = parent,
            .group_leader = parent orelse id,
            .flags = ProcessFlags{},
            .state = .embryo,
            .exit_reason = .normal,
            .heap_size = 0,
            .stack_size = 0,
            .message_queue_len = 0,
            .reductions = 0,
            .created_at = std.time.milliTimestamp(),
            .links = ArrayList(ProcessId).init(allocator),
            .monitors = ArrayList(ProcessId).init(allocator),
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.links.deinit();
        self.monitors.deinit();
    }
};

const Process = struct {
    info: ProcessInfo,
    stack: ArrayList(Term),
    registers: [256]Term,
    mailbox: MessageQueue,
    program_counter: usize,
    code: []Instruction,
    literals: []Term,
    catch_stack: ArrayList(CatchFrame),
    allocator: Allocator,
    gc: GarbageCollector,
    
    const Self = @This();
    
    const CatchFrame = struct {
        pc: usize,
        stack_size: usize,
        catch_type: enum { try_catch, catch_all },
    };
    
    pub fn init(allocator: Allocator, id: ProcessId, parent: ?ProcessId, code: []Instruction, literals: []Term) !*Self {
        const process = try allocator.create(Self);
        process.* = Self{
            .info = ProcessInfo.init(allocator, id, parent),
            .stack = ArrayList(Term).init(allocator),
            .registers = [_]Term{Term.make_nil()} ** 256,
            .mailbox = MessageQueue.init(allocator),
            .program_counter = 0,
            .code = code,
            .literals = literals,
            .catch_stack = ArrayList(CatchFrame).init(allocator),
            .allocator = allocator,
            .gc = GarbageCollector.init(allocator),
        };
        process.info.state = .runnable;
        return process;
    }
    
    pub fn deinit(self: *Self) void {
        self.info.deinit();
        self.stack.deinit();
        self.mailbox.deinit();
        self.catch_stack.deinit();
        self.gc.deinit();
        self.allocator.destroy(self);
    }
    
    pub fn send_message(self: *Self, message: Message) !void {
        try self.mailbox.send(message);
        self.info.message_queue_len = self.mailbox.messages.items.len;
        
        // Wake up process if waiting for messages
        if (self.info.state == .waiting) {
            self.info.state = .runnable;
        }
    }
    
    pub fn link_to(self: *Self, other_pid: ProcessId) !void {
        try self.info.links.append(other_pid);
    }
    
    pub fn unlink_from(self: *Self, other_pid: ProcessId) bool {
        for (self.info.links.items, 0..) |pid, i| {
            if (pid == other_pid) {
                _ = self.info.links.swapRemove(i);
                return true;
            }
        }
        return false;
    }
    
    pub fn monitor(self: *Self, other_pid: ProcessId) !void {
        try self.info.monitors.append(other_pid);
    }
    
    pub fn demonitor(self: *Self, other_pid: ProcessId) bool {
        for (self.info.monitors.items, 0..) |pid, i| {
            if (pid == other_pid) {
                _ = self.info.monitors.swapRemove(i);
                return true;
            }
        }
        return false;
    }
};

// ===== SCHEDULING SYSTEM =====
const SchedulerQueue = struct {
    processes: ArrayList(ProcessId),
    mutex: Mutex,
    condition: Condition,
    
    const Self = @This();
    
    pub fn init(allocator: Allocator) Self {
        return Self{
            .processes = ArrayList(ProcessId).init(allocator),
            .mutex = Mutex{},
            .condition = Condition{},
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.processes.deinit();
    }
    
    pub fn enqueue(self: *Self, pid: ProcessId) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        try self.processes.append(pid);
        self.condition.signal();
    }
    
    pub fn dequeue(self: *Self) ?ProcessId {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        if (self.processes.items.len > 0) {
            return self.processes.orderedRemove(0);
        }
        return null;
    }
    
    pub fn wait_for_work(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        
        while (self.processes.items.len == 0) {
            self.condition.wait(&self.mutex);
        }
    }
    
    pub fn len(self: *Self) usize {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.processes.items.len;
    }
};

const Scheduler = struct {
    id: u32,
    normal_queue: SchedulerQueue,
    high_queue: SchedulerQueue,
    max_queue: SchedulerQueue,
    current_process: ?ProcessId,
    reductions_left: u32,
    max_reductions: u32,
    total_reductions: u64,
    allocator: Allocator,
    
    const Self = @This();
    const DEFAULT_REDUCTIONS = 4000;
    
    pub fn init(allocator: Allocator, id: u32) Self {
        return Self{
            .id = id,
            .normal_queue = SchedulerQueue.init(allocator),
            .high_queue = SchedulerQueue.init(allocator),
            .max_queue = SchedulerQueue.init(allocator),
            .current_process = null,
            .reductions_left = DEFAULT_REDUCTIONS,
            .max_reductions = DEFAULT_REDUCTIONS,
            .total_reductions = 0,
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.normal_queue.deinit();
        self.high_queue.deinit();
        self.max_queue.deinit();
    }
    
    pub fn schedule_process(self: *Self, pid: ProcessId, priority: u4) !void {
        switch (priority) {
            0...3 => try self.normal_queue.enqueue(pid),
            4...7 => try self.high_queue.enqueue(pid),
            8...15 => try self.max_queue.enqueue(pid),
        }
    }
    
    pub fn get_next_process(self: *Self) ?ProcessId {
        // Priority: max > high > normal
        if (self.max_queue.dequeue()) |pid| {
            self.current_process = pid;
            self.reductions_left = self.max_reductions;
            return pid;
        }
        
        if (self.high_queue.dequeue()) |pid| {
            self.current_process = pid;
            self.reductions_left = self.max_reductions;
            return pid;
        }
        
        if (self.normal_queue.dequeue()) |pid| {
            self.current_process = pid;
            self.reductions_left = self.max_reductions;
            return pid;
        }
        
        return null;
    }
    
    pub fn yield_process(self: *Self, pid: ProcessId, priority: u4) !void {
        self.current_process = null;
        try self.schedule_process(pid, priority);
    }
    
    pub fn consume_reductions(self: *Self, count: u32) bool {
        if (self.reductions_left >= count) {
            self.reductions_left -= count;
            self.total_reductions += count;
            return true;
        }
        return false;
    }
    
    pub fn has_work(self: *Self) bool {
        return self.max_queue.len() > 0 or self.high_queue.len() > 0 or self.normal_queue.len() > 0;
    }
    
    pub fn wait_for_work(self: *Self) void {
        // Wait on any queue that might get work
        // In a real implementation, this would be more sophisticated
        if (!self.has_work()) {
            self.normal_queue.wait_for_work();
        }
    }
};

// ===== VIRTUAL MACHINE =====
const VM = struct {
    schedulers: ArrayList(*Scheduler),
    processes: HashMap(ProcessId, *Process, std.hash_map.AutoContext(ProcessId), std.hash_map.default_max_load_percentage),
    atom_table: AtomTable,
    next_pid: Atomic(ProcessId),
    running: Atomic(bool),
    allocator: Allocator,
    num_schedulers: u32,
    
    const Self = @This();
    
    pub fn init(allocator: Allocator, num_schedulers: u32) !Self {
        var schedulers = ArrayList(*Scheduler).init(allocator);
        
        for (0..num_schedulers) |i| {
            const scheduler = try allocator.create(Scheduler);
            scheduler.* = Scheduler.init(allocator, @intCast(i));
            try schedulers.append(scheduler);
        }
        
        return Self{
            .schedulers = schedulers,
            .processes = HashMap(ProcessId, *Process, std.hash_map.AutoContext(ProcessId), std.hash_map.default_max_load_percentage).init(allocator),
            .atom_table = AtomTable.init(allocator),
            .next_pid = Atomic(ProcessId).init(1),
            .running = Atomic(bool).init(false),
            .allocator = allocator,
            .num_schedulers = num_schedulers,
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.stop();
        
        for (self.schedulers.items) |scheduler| {
            scheduler.deinit();
            self.allocator.destroy(scheduler);
        }
        self.schedulers.deinit();
        
        var process_iter = self.processes.iterator();
        while (process_iter.next()) |entry| {
            entry.value_ptr.*.deinit();
        }
        self.processes.deinit();
        
        self.atom_table.deinit();
    }
    
    pub fn spawn_process(self: *Self, parent: ?ProcessId, code: []Instruction, literals: []Term) !ProcessId {
        const pid = self.next_pid.fetchAdd(1, .SeqCst);
        const process = try Process.init(self.allocator, pid, parent, code, literals);
        
        try self.processes.put(pid, process);
        
        // Schedule on first available scheduler
        const scheduler_id = pid % self.num_schedulers;
        try self.schedulers.items[scheduler_id].schedule_process(pid, 0);
        
        print("Spawned process {} on scheduler {}\n", .{ pid, scheduler_id });
        return pid;
    }
    
    pub fn send_message(self: *Self, from: ProcessId, to: ProcessId, data: Term) !void {
        const target_process = self.processes.get(to) orelse return VMError.ProcessNotFound;
        const message = Message.normal_message(from, to, data);
        try target_process.send_message(message);
    }
    
    pub fn link_processes(self: *Self, pid1: ProcessId, pid2: ProcessId) !void {
        const process1 = self.processes.get(pid1) orelse return VMError.ProcessNotFound;
        const process2 = self.processes.get(pid2) orelse return VMError.ProcessNotFound;
        
        try process1.link_to(pid2);
        try process2.link_to(pid1);
    }
    
    pub fn start(self: *Self) !void {
        self.running.store(true, .SeqCst);
        print("Starting VM with {} schedulers...\n", .{self.num_schedulers});
        
        // Start scheduler threads
        var threads = ArrayList(Thread).init(self.allocator);
        defer threads.deinit();
        
        for (self.schedulers.items) |scheduler| {
            const thread = try Thread.spawn(.{}, run_scheduler, .{ self, scheduler });
            try threads.append(thread);
        }
        
        // Wait for all scheduler threads to complete
        for (threads.items) |thread| {
            thread.join();
        }
        
        print("VM stopped.\n");
    }
    
    pub fn stop(self: *Self) void {
        self.running.store(false, .SeqCst);
        
        // Wake up all schedulers
        for (self.schedulers.items) |scheduler| {
            scheduler.normal_queue.condition.broadcast();
            scheduler.high_queue.condition.broadcast();
            scheduler.max_queue.condition.broadcast();
        }
    }
    
    fn run_scheduler(self: *Self, scheduler: *Scheduler) void {
        print("Scheduler {} started\n", .{scheduler.id});
        
        while (self.running.load(.SeqCst)) {
            if (scheduler.get_next_process()) |pid| {
                self.execute_process(scheduler, pid) catch |err| {
                    print("Scheduler {} err executing process {}: {}\n", .{ scheduler.id, pid, err });
                    // Kill the process on unhandled error
                    self.kill_process(pid, .err) catch {};
                };
            } else {
                // No work available, wait for more
                if (self.running.load(.SeqCst)) {
                    scheduler.wait_for_work();
                }
            }
        }
        
        print("Scheduler {} stopped\n", .{scheduler.id});
    }
    
    fn execute_process(self: *Self, scheduler: *Scheduler, pid: ProcessId) !void {
        const process = self.processes.get(pid) orelse return VMError.ProcessNotFound;
        
        if (process.info.state != .runnable) {
            return;
        }
        
        process.info.state = .running;
        
        while (scheduler.reductions_left > 0 and process.info.state == .running) {
            if (process.program_counter >= process.code.len) {
                // Process completed normally
                try self.exit_process(pid, .normal, Term.make_atom(try self.atom_table.intern("normal")));
                break;
            }
            
            const instruction = process.code[process.program_counter];
            try self.execute_instruction(process, instruction);
            
            process.program_counter += 1;
            process.info.reductions += 1;
            
            if (!scheduler.consume_reductions(1)) {
                // Out of reductions, yield process
                process.info.state = .runnable;
                try scheduler.yield_process(pid, process.info.flags.priority);
                break;
            }
        }
    }
    
    fn execute_instruction(self: *Self, process: *Process, instruction: Instruction) !void {
        switch (instruction.opcode) {
            .push_literal => {
                const literal_index = instruction.args[0];
                if (literal_index < process.literals.len) {
                    try process.stack.append(process.literals[literal_index]);
                } else {
                    return VMError.InvalidInstruction;
                }
            },
            
            .push_var => {
                const reg_index = instruction.args[0];
                if (reg_index < process.registers.len) {
                    try process.stack.append(process.registers[reg_index]);
                } else {
                    return VMError.InvalidInstruction;
                }
            },
            
            .pop => {
                if (process.stack.items.len > 0) {
                    _ = process.stack.pop();
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .dup => {
                if (process.stack.items.len > 0) {
                    const top = process.stack.items[process.stack.items.len - 1];
                    try process.stack.append(top);
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .swap => {
                if (process.stack.items.len >= 2) {
                    const len = process.stack.items.len;
                    const temp = process.stack.items[len - 1];
                    process.stack.items[len - 1] = process.stack.items[len - 2];
                    process.stack.items[len - 2] = temp;
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .add => {
                if (process.stack.items.len >= 2) {
                    const b = process.stack.pop();
                    const a = process.stack.pop();
                    
                    if (a.tag == .small_integer and b.tag == .small_integer) {
                        const result = Term.make_integer(a.data.small_int + b.data.small_int);
                        try process.stack.append(result);
                    } else if (a.tag == .float and b.tag == .float) {
                        const result = Term{ .tag = .float, .data = .{ .float = a.data.float + b.data.float } };
                        try process.stack.append(result);
                    } else {
                        return VMError.InvalidType;
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .sub => {
                if (process.stack.items.len >= 2) {
                    const b = process.stack.pop();
                    const a = process.stack.pop();
                    
                    if (a.tag == .small_integer and b.tag == .small_integer) {
                        const result = Term.make_integer(a.data.small_int - b.data.small_int);
                        try process.stack.append(result);
                    } else if (a.tag == .float and b.tag == .float) {
                        const result = Term{ .tag = .float, .data = .{ .float = a.data.float - b.data.float } };
                        try process.stack.append(result);
                    } else {
                        return VMError.InvalidType;
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .mul => {
                if (process.stack.items.len >= 2) {
                    const b = process.stack.pop();
                    const a = process.stack.pop();
                    
                    if (a.tag == .small_integer and b.tag == .small_integer) {
                        const result = Term.make_integer(a.data.small_int * b.data.small_int);
                        try process.stack.append(result);
                    } else if (a.tag == .float and b.tag == .float) {
                        const result = Term{ .tag = .float, .data = .{ .float = a.data.float * b.data.float } };
                        try process.stack.append(result);
                    } else {
                        return VMError.InvalidType;
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .div_int => {
                if (process.stack.items.len >= 2) {
                    const b = process.stack.pop();
                    const a = process.stack.pop();
                    
                    if (a.tag == .small_integer and b.tag == .small_integer) {
                        if (b.data.small_int == 0) {
                            return VMError.err; // Division by zero
                        }
                        const result = Term.make_integer(@divTrunc(a.data.small_int, b.data.small_int));
                        try process.stack.append(result);
                    } else {
                        return VMError.InvalidType;
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .eq => {
                if (process.stack.items.len >= 2) {
                    const b = process.stack.pop();
                    const a = process.stack.pop();
                    const result = Term.make_atom(if (terms_equal(a, b)) 
                        try self.atom_table.intern("true") 
                    else 
                        try self.atom_table.intern("false"));
                    try process.stack.append(result);
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .spawn => {
                // In a real implementation, this would take module/function/args
                // For now, we'll create a simple test process
                const test_code = [_]Instruction{
                    Instruction.make(.push_literal),
                    Instruction.make(.halt),
                };
                const test_literals = [_]Term{Term.make_integer(42)};
                
                const new_pid = try self.spawn_process(process.info.id, &test_code, &test_literals);
                const pid_term = Term.make_pid(new_pid);
                try process.stack.append(pid_term);
            },
            
            .send => {
                if (process.stack.items.len >= 2) {
                    const message = process.stack.pop();
                    const target = process.stack.pop();
                    
                    if (target.tag == .pid) {
                        try self.send_message(process.info.id, target.data.pid, message);
                        try process.stack.append(message); // Return the message
                    } else {
                        return VMError.InvalidType;
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .receive => {
                if (process.mailbox.receive()) |message| {
                    try process.stack.append(message.data);
                } else {
                    // No messages, suspend process
                    process.info.state = .waiting;
                    process.program_counter -= 1; // Stay on this instruction
                }
            },
            
            .receive_timeout => {
                const timeout = instruction.args[0];
                if (process.mailbox.receive_timeout(timeout)) |message| {
                    try process.stack.append(message.data);
                } else {
                    // Timeout, push timeout atom
                    const timeout_atom = Term.make_atom(try self.atom_table.intern("timeout"));
                    try process.stack.append(timeout_atom);
                }
            },
            
            .make_tuple => {
                const arity = instruction.args[0];
                if (process.stack.items.len >= arity) {
                    // Create tuple from stack elements
                    const tuple_obj = try process.gc.allocate_object(.tuple, @sizeOf(TupleData) + arity * @sizeOf(Term));
                    const tuple_data = @as(*TupleData, @ptrCast(@alignCast(tuple_obj.data.ptr)));
                    tuple_data.arity = arity;
                    
                    const elements_ptr = @as([*]Term, @ptrCast(@alignCast(tuple_obj.data.ptr + @sizeOf(TupleData))));
                    tuple_data.elements = elements_ptr[0..arity];
                    
                    // Pop elements from stack in reverse order
                    var i: usize = arity;
                    while (i > 0) {
                        i -= 1;
                        tuple_data.elements[i] = process.stack.pop();
                    }
                    
                    const tuple_term = Term{ .tag = .tuple, .data = .{ .tuple = tuple_data } };
                    try process.stack.append(tuple_term);
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .get_tuple_element => {
                const index = instruction.args[0];
                if (process.stack.items.len > 0) {
                    const tuple_term = process.stack.pop();
                    if (tuple_term.tag == .tuple) {
                        const tuple_data = tuple_term.data.tuple;
                        if (index < tuple_data.arity) {
                            try process.stack.append(tuple_data.elements[index]);
                        } else {
                            return VMError.InvalidInstruction;
                        }
                    } else {
                        return VMError.InvalidType;
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .jump => {
                const offset = @as(i32, @bitCast(instruction.args[0]));
                process.program_counter = @intCast(@as(i64, @intCast(process.program_counter)) + offset - 1);
            },
            
            .jump_if_true => {
                if (process.stack.items.len > 0) {
                    const condition = process.stack.pop();
                    if (is_truthy(condition)) {
                        const offset = @as(i32, @bitCast(instruction.args[0]));
                        process.program_counter = @intCast(@as(i64, @intCast(process.program_counter)) + offset - 1);
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .jump_if_false => {
                if (process.stack.items.len > 0) {
                    const condition = process.stack.pop();
                    if (!is_truthy(condition)) {
                        const offset = @as(i32, @bitCast(instruction.args[0]));
                        process.program_counter = @intCast(@as(i64, @intCast(process.program_counter)) + offset - 1);
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .call => {
                // In a real implementation, this would look up the function and call it
                // For now, just print debug info
                const module = instruction.args[0];
                const function = instruction.args[1];
                const arity = instruction.args[2];
                print("Process {} calling function {}/{}/{}\n", .{ process.info.id, module, function, arity });
            },
            
            .ret => {
                // In a real implementation, this would return from function calls
                print("Process {} returning from function\n", .{process.info.id});
            },
            
            .exit => {
                const reason = if (process.stack.items.len > 0) 
                    process.stack.pop() 
                else 
                    Term.make_atom(try self.atom_table.intern("normal"));
                try self.exit_process(process.info.id, .exit, reason);
            },
            
            .link => {
                if (process.stack.items.len > 0) {
                    const target = process.stack.pop();
                    if (target.tag == .pid) {
                        try self.link_processes(process.info.id, target.data.pid);
                        try process.stack.append(Term.make_atom(try self.atom_table.intern("true")));
                    } else {
                        return VMError.InvalidType;
                    }
                } else {
                    return VMError.StackUnderflow;
                }
            },
            
            .gc => {
                // Force garbage collection
                try process.gc.collect_garbage();
            },
            
            .halt => {
                try self.exit_process(process.info.id, .normal, Term.make_atom(try self.atom_table.intern("normal")));
            },
            
            .nop => {
                // No operation
            },
            
            else => {
                print("Unimplemented instruction: {} in process {}\n", .{ instruction.opcode, process.info.id });
                return VMError.InvalidInstruction;
            },
        }
    }
    
    fn exit_process(self: *Self, pid: ProcessId, reason: ExitReason, exit_term: Term) !void {
        const process = self.processes.get(pid) orelse return;
        
        process.info.state = .exiting;
        process.info.exit_reason = reason;
        
        // Send exit signals to linked processes
        for (process.info.links.items) |linked_pid| {
            if (self.processes.get(linked_pid)) |linked_process| {
                if (!linked_process.info.flags.trap_exit) {
                    // Propagate exit
                    try self.exit_process(linked_pid, reason, exit_term);
                } else {
                    // Send exit message
                    const exit_msg = Message.exit_message(pid, linked_pid, exit_term);
                    try linked_process.send_message(exit_msg);
                }
            }
        }
        
        // Send monitor messages
        for (process.info.monitors.items) |monitor_pid| {
            if (self.processes.get(monitor_pid)) |monitor_process| {
                const monitor_msg = Message{
                    .msg_type = .monitor,
                    .from = pid,
                    .to = monitor_pid,
                    .data = exit_term,
                    .timestamp = std.time.milliTimestamp(),
                    .ref = null,
                };
                try monitor_process.send_message(monitor_msg);
            }
        }
        
        process.info.state = .dead;
        print("Process {} exited with reason: {}\n", .{ pid, reason });
    }
    
    fn kill_process(self: *Self, pid: ProcessId, reason: ExitReason) !void {
        const killed_atom = Term.make_atom(try self.atom_table.intern("killed"));
        try self.exit_process(pid, reason, killed_atom);
    }
};

// ===== UTILITY FUNCTIONS =====
fn terms_equal(a: Term, b: Term) bool {
    if (a.tag != b.tag) return false;
    
    switch (a.tag) {
        .small_integer => return a.data.small_int == b.data.small_int,
        .float => return a.data.float == b.data.float,
        .atom => return a.data.atom == b.data.atom,
        .pid => return a.data.pid == b.data.pid,
        .nil => return true,
        else => return false, // Simplified comparison
    }
}

fn is_truthy(term: Term) bool {
    switch (term.tag) {
        .atom => {
            // Only 'false' and 'nil' atoms are falsy
            // This would need atom table lookup in real implementation
            return true; // Simplified
        },
        .nil => return false,
        .small_integer => return term.data.small_int != 0,
        else => return true,
    }
}

// ===== BUILT-IN FUNCTIONS (BIFs) =====
const BIF = struct {
    pub fn spawn_bif(args: []Term) VMError!Term {
        // spawn(Module, Function, Args)
        if (args.len != 3) return VMError.BadArity;
        
        // In a real implementation, this would create a new process
        // For now, return a dummy PID
        return Term.make_pid(9999);
    }
    
    pub fn send_bif(args: []Term) VMError!Term {
        // Dest ! Message
        if (args.len != 2) return VMError.BadArity;
        
        // In a real implementation, this would send the message
        return args[1]; // Return the message
    }
    
    pub fn self_bif(args: []Term) VMError!Term {
        if (args.len != 0) return VMError.BadArity;
        
        // In a real implementation, this would return the current process PID
        return Term.make_pid(1);
    }
    
    pub fn length_bif(args: []Term) VMError!Term {
        if (args.len != 1) return VMError.BadArity;
        
        const list_term = args[0];
        if (list_term.tag != .list) return VMError.InvalidType;
        
        // In a real implementation, this would calculate list length
        return Term.make_integer(0);
    }
    
    pub fn tuple_size_bif(args: []Term) VMError!Term {
        if (args.len != 1) return VMError.BadArity;
        
        const tuple_term = args[0];
        if (tuple_term.tag != .tuple) return VMError.InvalidType;
        
        const tuple_data = tuple_term.data.tuple;
        return Term.make_integer(@intCast(tuple_data.arity));
    }
};

// ===== MAIN FUNCTION AND EXAMPLES =====
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Detect number of CPU cores for schedulers
    const num_schedulers = @max(1, @min(8, std.Thread.getCpuCount() catch 4));
    
    var vm = try VM.init(allocator, num_schedulers);
    defer vm.deinit();
    
    // Create sample programs
    const main_program = [_]Instruction{
        Instruction.make1(.push_literal, 0), // Push "hello"
        Instruction.make1(.push_literal, 1), // Push 42
        Instruction.make2(.make_tuple, 2, 0), // Make {hello, 42}
        Instruction.make(.spawn),             // Spawn child process
        Instruction.make(.dup),               // Duplicate PID
        Instruction.make1(.push_literal, 2),  // Push "world"
        Instruction.make(.send),              // Send message
        Instruction.make1(.receive_timeout, 5000), // Wait for reply
        Instruction.make(.halt),
    };
    
    const child_program = [_]Instruction{
        Instruction.make(.receive),           // Wait for message
        Instruction.make1(.push_literal, 3),  // Push "reply"
        Instruction.make(.swap),              // Swap message and reply
        Instruction.make(.pop),               // Remove original message
        // Here we would send reply back, but simplified for demo
        Instruction.make(.halt),
    };
    
    const main_literals = [_]Term{
        Term.make_atom(try vm.atom_table.intern("hello")),
        Term.make_integer(42),
        Term.make_atom(try vm.atom_table.intern("world")),
        Term.make_atom(try vm.atom_table.intern("reply")),
    };
    
    const child_literals = [_]Term{
        Term.make_atom(try vm.atom_table.intern("ok")),
    };
    
    // Spawn initial processes
    const main_pid = try vm.spawn_process(null, &main_program, &main_literals);
    const child_pid = try vm.spawn_process(main_pid, &child_program, &child_literals);
    
    print("Created main process: {}\n", .{main_pid});
    print("Created child process: {}\n", .{child_pid});
    
    // Link processes for supervision
    try vm.link_processes(main_pid, child_pid);
    
    // Start the VM (this will block until all processes complete)
    // In a real system, you'd want to handle this differently
    const vm_thread = try Thread.spawn(.{}, VM.start, .{&vm});
    
    // Let it run for a bit, then stop
    std.time.sleep(2 * std.time.ns_per_s);
    vm.stop();
    
    vm_thread.join();
    
    print("VM demo completed successfully!\n");
}
-- ==============================================================================
-- advanced/async_coroutine_scheduler.lua: Asynchronous Event Loop & Channels
-- Compatible with: LuaJIT
-- Run with: luajit advanced/async_coroutine_scheduler.lua
-- ==============================================================================

-- A lightweight cooperative async scheduler / mini event loop built on Lua coroutines.
-- Supports task spawning, non-blocking sleep, and inter-task channels.

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
    return setmetatable({
        ready_queue = {},   -- list of coroutines ready to run immediately
        sleepers    = {},   -- list of { wake_time = t, co = coroutine }
        current_time = 0.0, -- simulated or monotonic clock
    }, Scheduler)
end

function Scheduler:spawn(fn, name)
    local co = coroutine.create(fn)
    table.insert(self.ready_queue, { co = co, name = name or "task" })
    return co
end

-- Yields the current task until 'duration' seconds have passed
function Scheduler:sleep(duration)
    coroutine.yield({ type = "sleep", duration = duration })
end

-- Yields control to other ready tasks immediately
function Scheduler:yield_task()
    coroutine.yield({ type = "yield" })
end

-- High-resolution time using os.clock()
local function get_clock()
    return os.clock()
end

function Scheduler:run()
    local start_real_time = get_clock()

    while #self.ready_queue > 0 or #self.sleepers > 0 do
        local now = get_clock() - start_real_time

        -- 1. Check sleeping tasks and move awakened ones to ready_queue
        local i = 1
        while i <= #self.sleepers do
            local item = self.sleepers[i]
            if now >= item.wake_time then
                table.remove(self.sleepers, i)
                table.insert(self.ready_queue, { co = item.co, name = item.name })
            else
                i = i + 1
            end
        end

        -- 2. Execute next ready task
        if #self.ready_queue > 0 then
            local task = table.remove(self.ready_queue, 1)
            local ok, command = coroutine.resume(task.co)

            if not ok then
                print(string.format("  [ERROR] in task '%s': %s", task.name, tostring(command)))
            elseif coroutine.status(task.co) ~= "dead" then
                -- Handle scheduler commands yielded by the task
                if command and command.type == "sleep" then
                    table.insert(self.sleepers, {
                        co = task.co,
                        name = task.name,
                        wake_time = now + command.duration,
                    })
                else
                    -- Standard cooperative yield: place back at end of ready queue
                    table.insert(self.ready_queue, task)
                end
            end
        end
    end
end

-- ==============================================================================
-- Inter-Task Communication: Asynchronous Channels
-- ==============================================================================
local function create_channel(scheduler)
    local queue = {}
    return {
        send = function(msg)
            table.insert(queue, msg)
            scheduler:yield_task()
        end,
        recv = function()
            while #queue == 0 do
                scheduler:yield_task()
            end
            return table.remove(queue, 1)
        end
    }
end

-- ==============================================================================
-- Demonstration Tasks
-- ==============================================================================
print("=== Running Async Coroutine Event Loop ===")

local sched = Scheduler.new()
local chan = create_channel(sched)

-- Task 1: Periodic ticker
sched:spawn(function()
    for i = 1, 3 do
        print(string.format("  [Ticker] Tick #%d at t=%.2fs", i, get_clock()))
        sched:sleep(0.02) -- non-blocking sleep for 20ms
    end
    print("  [Ticker] Completed!")
end, "TickerTask")

-- Task 2: Message Producer
sched:spawn(function()
    local messages = { "Init handshake", "Fetch metrics", "Heartbeat ping", "Shutdown" }
    for _, msg in ipairs(messages) do
        print(string.format("  [Producer] Sending message: '%s'", msg))
        chan.send(msg)
        sched:sleep(0.01)
    end
end, "ProducerTask")

-- Task 3: Message Consumer
sched:spawn(function()
    while true do
        local msg = chan.recv()
        print(string.format("  [Consumer] Received and processed: '%s'", msg))
        if msg == "Shutdown" then
            print("  [Consumer] Shutdown signal received, terminating worker.")
            break
        end
    end
end, "ConsumerTask")

-- Run the event loop
sched:run()

print("\n[OK] advanced/async_coroutine_scheduler.lua completed successfully.")

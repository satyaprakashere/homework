package main

import "core:bufio"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:time"

// Sample station names with baseline temperatures (tenths of a degree Celsius)
Station :: struct {
    name:     string,
    mean_temp: i32, // e.g. 152 = 15.2°C
}

STATIONS := [?]Station{
    {"Abidjan", 260},
    {"Abu Dhabi", 270},
    {"Amsterdam", 102},
    {"Ankara", 120},
    {"Asuncion", 209},
    {"Athens", 192},
    {"Bangkok", 286},
    {"Barcelona", 182},
    {"Beijing", 129},
    {"Berlin", 103},
    {"Bogota", 140},
    {"Boston", 109},
    {"Buenos Aires", 175},
    {"Cairo", 214},
    {"Cape Town", 162},
    {"Chicago", 98},
    {"Delhi", 250},
    {"Dhaka", 259},
    {"Dubai", 269},
    {"Dublin", 98},
    {"Helsinki", 59},
    {"Hong Kong", 233},
    {"Istanbul", 139},
    {"Jakarta", 267},
    {"Kathmandu", 183},
    {"London", 113},
    {"Madrid", 150},
    {"Melbourne", 151},
    {"Mexico City", 159},
    {"Moscow", 58},
    {"Mumbai", 271},
    {"Nairobi", 178},
    {"New York", 127},
    {"Oslo", 57},
    {"Paris", 123},
    {"Prague", 84},
    {"Reykjavik", 43},
    {"Rome", 152},
    {"San Francisco", 146},
    {"Seoul", 125},
    {"Singapore", 270},
    {"Stockholm", 66},
    {"Sydney", 177},
    {"Tokyo", 154},
    {"Toronto", 94},
    {"Vienna", 104},
    {"Warsaw", 85},
    {"Zurich", 93},
}

main :: proc() {
    num_rows := 10_000_000 // Default: 10 Million rows (change to 1_000_000_000 for full 1B)
    output_filename := "measurements.txt"

    if len(os.args) > 1 {
        parsed_rows, ok := strconv.parse_int(os.args[1])
        if ok && parsed_rows > 0 {
            num_rows = parsed_rows
        }
    }

    fmt.printf("Generating %d rows into '%s'...\n", num_rows, output_filename)
    start_time := time.now()

    handle, err := os.open(output_filename, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
    if err != nil {
        fmt.eprintln("Failed to create file:", err)
        return
    }
    defer os.close(handle)

    // Wrap output handle in a 256KB buffered writer for max disk throughput
    write_buffer: [256 * 1024]u8 = ---
    bw: bufio.Writer
    bufio.writer_init_with_buf(&bw, os.stream_from_handle(handle), write_buffer[:])
    defer bufio.writer_flush(&bw)

    writer_stream := bufio.writer_to_stream(&bw)

    // Scratch buffers for zero-allocation integer formatting
    itoa_buf: [32]u8 = ---

    for i in 0 ..< num_rows {
        // Pick a random station
        station_idx := rand.int_max(len(STATIONS))
        station := STATIONS[station_idx]

        // Temperature generation: Gaussian-ish variation around mean
        // Delta between -10.0°C and +10.0°C (-100 to +100 tenths)
        delta := i32(rand.int_max(201)) - 100
        temp_tenths := station.mean_temp + delta

        // Format station string + ';'
        bufio.write_string(writer_stream, station.name)
        bufio.write_byte(writer_stream, ';')

        // Format temperature manually to avoid fmt.fprintf allocation cost
        if temp_tenths < 0 {
            bufio.write_byte(writer_stream, '-')
            temp_tenths = -temp_tenths
        }

        whole := temp_tenths / 10
        fraction := temp_tenths % 10

        whole_str := strconv.itoa(itoa_buf[:], int(whole))
        bufio.write_string(writer_stream, whole_str)
        bufio.write_byte(writer_stream, '.')

        frac_str := strconv.itoa(itoa_buf[:], int(fraction))
        bufio.write_string(writer_stream, frac_str)
        bufio.write_byte(writer_stream, '\n')
    }

    bufio.writer_flush(&bw)

    elapsed := time.since(start_time)
    fmt.printf("Done! Generated %d rows in %v\n", num_rows, elapsed)
}

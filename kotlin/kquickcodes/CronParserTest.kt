import CronParser
import kotlin.test.*


class KronParserTest {
    private val parser = CronParser()
    
    @Test
    fun parse_fixed_values() {
        val result = parser.parse("0 12 15 6 3 /usr/bin/grep")
        
        assertEquals(listOf(0), result.minute)
        assertEquals(listOf(12), result.hour)
        assertEquals(listOf(15), result.dayOfMonth)
        assertEquals(listOf(6), result.month)
        assertEquals(listOf(3), result.dayOfWeek)
    }
    
    @Test
    fun parse_wildcards() {
        val result = parser.parse("* * * * * /opt/bin/grep")
        
        assertEquals((0..59).toList(), result.minute)
        assertEquals((0..23).toList(), result.hour)
        assertEquals((1..31).toList(), result.dayOfMonth)
        assertEquals((1..12).toList(), result.month)
        assertEquals((1..7).toList(), result.dayOfWeek)
    }
    
    @Test
    fun parse_ranges_and_steps() {
        val result = parser.parse("*/20 0 1,15 * 1-5 /opt/bin/find")
        
        assertEquals(listOf(0, 20, 40), result.minute)
        assertEquals(listOf(0), result.hour)
        assertEquals(listOf(1, 15), result.dayOfMonth)
        assertEquals((1..12).toList(), result.month)
        assertEquals((1..5).toList(), result.dayOfWeek)
    }
    
    @Test
    fun throws_on_invalid_minute() {
        assertFailsWith<IllegalArgumentException> { parser.parse("61 * * * * /opt/bin/cat") }
        assertFailsWith<IllegalArgumentException> { parser.parse("0 * * * 7-5 /opt/bin/cat") }
    }
}

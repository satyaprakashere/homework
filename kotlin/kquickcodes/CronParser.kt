import kotlin.system.exitProcess

data class CronExpression(
    val minute: List<Int>,
    val hour: List<Int>,
    val dayOfMonth: List<Int>,
    val month: List<Int>,
    val dayOfWeek: List<Int>,
    val command: String
)


class CronParser {
    companion object {
        private val fieldNames =
                listOf("minute", "hour", "day of month", "month", "day of week", "command")
        private val exprRange = listOf(0..59, 0..23, 1..31, 1..12, 1..7)

        @JvmStatic
        fun main(args: Array<String>) {
            // fieldNames.
            if (args.size == 1) {
                val cronParser = CronParser()
                val cron = cronParser.parse(args[0])
                cronParser.toFieldMap(cron).forEach { (key, value) -> println("$key$value") }
            } else {
                println("Please provide a single cron expression.")
                exitProcess(64)
            }
        }
    }

    fun toFieldMap(cron: CronExpression): Map<String, String> {
        val exp =
                listOf(cron.minute, cron.hour, cron.dayOfMonth, cron.month, cron.dayOfWeek).map {
                    x -> x.toString().removePrefix("[").removeSuffix("]").replace(",", "")
                } + cron.command

        return fieldNames.map { it.padEnd(14) }.zip(exp).toMap()
    }

    fun parse(expr: String): CronExpression {
        val parts = expr.trim().split("\\s+".toRegex())

        val command = parts.subList(5, parts.size).joinToString("")
        require(parts.size in 5..6) { "Invalid cron expression: $expr" }

        return CronExpression(
                expandCronField(parts[0], exprRange[0]),
                expandCronField(parts[1], exprRange[1]),
                expandCronField(parts[2], exprRange[2]),
                expandCronField(parts[3], exprRange[3]),
                expandCronField(parts[4], exprRange[4]),
                command,
        )
    }

    private fun validate(expr: CronExpression) {
        assert(expr.minute.all { it in exprRange[0] })
        assert(expr.hour.all { it in exprRange[1] })
        assert(expr.dayOfMonth.all { it in exprRange[2] })
        assert(expr.month.all { it in exprRange[3] })
        assert(expr.dayOfWeek.all { it in exprRange[4] })
    }

    private fun expandCronField(expr: String, range: IntRange): List<Int> {
        return when {
            expr == "*" -> range.toList()
            expr.startsWith("*/") -> {
                val step = expr.removePrefix("*/").toInt()
                range.filter { it % step == 0 }
            }
            "," in expr -> expr.split(",").map { it.toInt() }
            "-" in expr -> {
                val (start, end) = expr.split("-").map { it.toInt() }
                (start..end).toList()
            }
            else ->
                if (expr.toInt() in range) {
                    listOf(expr.toInt())
                } else {
                    listOf()
                }
        }
    }
}

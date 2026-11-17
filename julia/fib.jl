function fibiter(n)
    a, b = UInt64(0), UInt64(1)
    for _ in 1:n
        a, b = b, a + b
    end
    return a
end

println(fibiter(98765432))


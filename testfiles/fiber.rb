a = []
fiber = Fiber.new { 3.times { |i| a << Fiber.yield(i) } }
n = -1
4.times { n = fiber.resume(n * 3) }
p a
fiber.resume(-1)

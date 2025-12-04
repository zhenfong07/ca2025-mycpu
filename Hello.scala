// See LICENSE.txt for license details.
package hello

import chisel3._
import chisel3.util._ // Import 'util' to use Mux (Multiplexer)
import chisel3.iotesters.{PeekPokeTester, Driver}

// --- 1. HARDWARE DEFINITION (The Module) ---
class LogicCircuit extends Module {
  val io = IO(new Bundle {
    val a      = Input(UInt(8.W))  // Input A (8-bit width)
    val b      = Input(UInt(8.W))  // Input B (8-bit width)
    val enable = Input(Bool())     // Control signal (Boolean: 1 bit)
    val out    = Output(UInt(8.W)) // Output (8-bit width)
  })

  // LOGIC DESCRIPTION:
  // A Multiplexer (Mux) selects between two values based on a condition.
  // Logic: If (io.enable is True) return (io.a + io.b), else return (0).
  io.out := Mux(io.enable, io.a + io.b, 0.U)
}

// --- 2. VERIFICATION (The Tester) ---
class LogicTests(c: LogicCircuit) extends PeekPokeTester(c) {
  
  // Test Case 1: Enable is OFF
  poke(c.io.a, 10)         // Drive input A with 10
  poke(c.io.b, 20)         // Drive input B with 20
  poke(c.io.enable, false) // Drive enable with False (0)
  step(1)                  // Advance clock by 1 cycle
  expect(c.io.out, 0)      // Assert that output is 0
  println(s"Test 1 (Enable OFF): Output = ${peek(c.io.out)}")

  // Test Case 2: Enable is ON
  poke(c.io.a, 10)
  poke(c.io.b, 20)
  poke(c.io.enable, true)  // Drive enable with True (1)
  step(1)
  expect(c.io.out, 30)     // Assert that output is 30 (10 + 20)
  println(s"Test 2 (Enable ON):  Output = ${peek(c.io.out)}")
  
  // Test Case 3: Different Values
  poke(c.io.a, 42)
  poke(c.io.b, 8)
  poke(c.io.enable, true)
  step(1)
  expect(c.io.out, 50)     // Assert that output is 50 (42 + 8)
  println(s"Test 3 (42 + 8):     Output = ${peek(c.io.out)}")
}

// --- 3. MAIN ENTRY POINT ---
object Hello {
  def main(args: Array[String]): Unit = {
    // Compiles the Chisel code to Verilog and runs the tests
    if (!Driver(() => new LogicCircuit())(c => new LogicTests(c))) System.exit(1)
  }
}
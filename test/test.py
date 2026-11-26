# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, Timer


@cocotb.test()
async def test_project(dut):

    # Reloj de 10 MHz
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    TIMEOUT = 1000000

    async def esperar(ciclos):
        await ClockCycles(dut.clk, ciclos)
        await FallingEdge(dut.clk)

    async def reiniciar():
        dut.rst_n.value = 0
        dut.ui_in.value = 0

        await esperar(10)

        dut.rst_n.value = 1

        await esperar(5)

    # PRUEBA 1: REPOSO
    await reiniciar()

    assert int(dut.uo_out.value) == 0b00000000

    dut._log.info("Reposo correcto")

    # PRUEBA 2: MOVIMIENTO NORMAL X-Y
    await reiniciar()

    for i in range(20):

        dut.ui_in.value = 0b00001111
        await esperar(5)

        dut.ui_in.value = 0b00000011
        await esperar(5)

        assert int(dut.uo_out.value) == 0

    dut._log.info("Movimiento normal correcto")

    # PRUEBA 3: LIMITE X POSITIVO
    await reiniciar()

    dut.ui_in.value = 0b00010001
    await esperar(5)

    assert int(dut.uo_out.value) == 0b11000100

    dut._log.info("Limite X+ correcto")

    # PRUEBA 4: LIMITE X NEGATIVO
    await reiniciar()

    dut.ui_in.value = 0b00100001
    await esperar(5)

    assert int(dut.uo_out.value) == 0b11001000

    dut._log.info("Limite X- correcto")

    # PRUEBA 5: LIMITE Y POSITIVO
    await reiniciar()

    dut.ui_in.value = 0b01000010
    await esperar(5)

    assert int(dut.uo_out.value) == 0b11010000

    dut._log.info("Limite Y+ correcto")

    # PRUEBA 6: LIMITE Y NEGATIVO
    await reiniciar()

    dut.ui_in.value = 0b10000010
    await esperar(5)

    assert int(dut.uo_out.value) == 0b11100000

    dut._log.info("Limite Y- correcto")

    # PRUEBA 7: BLOQUEO MECANICO X
    await reiniciar()

    dut.ui_in.value = 0b00000001

    await Timer((TIMEOUT + 10) * 100, unit="ns")
    await FallingEdge(dut.clk)

    assert int(dut.uo_out.value) == 0b11000001

    dut._log.info("Bloqueo X correcto")

    # PRUEBA 8: BLOQUEO MECANICO Y
    await reiniciar()

    dut.ui_in.value = 0b00001010

    await Timer((TIMEOUT + 10) * 100, unit="ns")
    await FallingEdge(dut.clk)

    assert int(dut.uo_out.value) == 0b11000010

    dut._log.info("Bloqueo Y correcto")

    # PRUEBA 9: MEMORIA DE FALLAS
    dut.ui_in.value = 0
    await esperar(5)

    assert int(dut.uo_out.value) == 0b11000010

    dut._log.info("Memoria de fallas correcta")

    # PRUEBA 10: REINICIO
    await reiniciar()

    assert int(dut.uo_out.value) == 0b00000000

    dut._log.info("Reinicio correcto")

    dut._log.info("TODAS LAS PRUEBAS CORRECTAS")

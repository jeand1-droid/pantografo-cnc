/*
 * Detector de fallas para pantografo de corte X-Y
 * SPDX-License-Identifier: Apache-2.0 
 */

`default_nettype none

module tt_um_example #(
    parameter integer TIMEOUT = 1000000
)(
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // SINCRONIZACION DE ENTRADAS

    reg [7:0] sync1;
    reg [7:0] sync2;

    always @(posedge clk) begin
        if (!rst_n) begin
            sync1 <= 8'b0;
            sync2 <= 8'b0;
        end else begin
            sync1 <= ui_in;
            sync2 <= sync1;
        end
    end

    // ENTRADAS DEL PANTOGRAFO

    wire mov_x     = sync2[0];
    wire mov_y     = sync2[1];

    wire enc_x     = sync2[2];
    wire enc_y     = sync2[3];

    wire lim_x_pos = sync2[4];
    wire lim_x_neg = sync2[5];

    wire lim_y_pos = sync2[6];
    wire lim_y_neg = sync2[7];

    // DETECCION DE CAMBIOS DEL ENCODER

    reg enc_x_ant;
    reg enc_y_ant;

    wire pulso_x = enc_x ^ enc_x_ant;
    wire pulso_y = enc_y ^ enc_y_ant;

    // CONTADORES DE TIEMPO

    localparam integer WIDTH =
        (TIMEOUT > 1) ? $clog2(TIMEOUT) : 1;

    localparam [WIDTH-1:0] LIMITE = TIMEOUT - 1;

    reg [WIDTH-1:0] contador_x;
    reg [WIDTH-1:0] contador_y;

    // REGISTROS DE FALLAS

    reg bloqueo_x;
    reg bloqueo_y;

    reg falla_x_pos;
    reg falla_x_neg;

    reg falla_y_pos;
    reg falla_y_neg;

    // LOGICA PRINCIPAL

    always @(posedge clk) begin

        if (!rst_n) begin

            enc_x_ant <= 1'b0;
            enc_y_ant <= 1'b0;

            contador_x <= 0;
            contador_y <= 0;

            bloqueo_x <= 1'b0;
            bloqueo_y <= 1'b0;

            falla_x_pos <= 1'b0;
            falla_x_neg <= 1'b0;

            falla_y_pos <= 1'b0;
            falla_y_neg <= 1'b0;

        end else begin

            enc_x_ant <= enc_x;
            enc_y_ant <= enc_y;

            // BLOQUEO MECANICO X

            if (!mov_x || pulso_x) begin
                contador_x <= 0;
            end else if (!bloqueo_x) begin

                if (contador_x == LIMITE)
                    bloqueo_x <= 1'b1;
                else
                    contador_x <= contador_x + 1'b1;

            end

            // BLOQUEO MECANICO Y

            if (!mov_y || pulso_y) begin
                contador_y <= 0;
            end else if (!bloqueo_y) begin

                if (contador_y == LIMITE)
                    bloqueo_y <= 1'b1;
                else
                    contador_y <= contador_y + 1'b1;

            end

            // LIMITES DE RECORRIDO X

            if (mov_x && lim_x_pos)
                falla_x_pos <= 1'b1;

            if (mov_x && lim_x_neg)
                falla_x_neg <= 1'b1;

            // LIMITES DE RECORRIDO Y

            if (mov_y && lim_y_pos)
                falla_y_pos <= 1'b1;

            if (mov_y && lim_y_neg)
                falla_y_neg <= 1'b1;

        end
    end

    // ALARMA GENERAL

    wire alarma;

    assign alarma = bloqueo_x   |
                    bloqueo_y   |
                    falla_x_pos |
                    falla_x_neg |
                    falla_y_pos |
                    falla_y_neg;

    // SALIDAS DIGITALES

    assign uo_out[0] = bloqueo_x;
    assign uo_out[1] = bloqueo_y;

    assign uo_out[2] = falla_x_pos;
    assign uo_out[3] = falla_x_neg;

    assign uo_out[4] = falla_y_pos;
    assign uo_out[5] = falla_y_neg;

    assign uo_out[6] = alarma;
    assign uo_out[7] = alarma;

    // PINES BIDIRECCIONALES NO UTILIZADOS

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire _unused = &{ena, uio_in, 1'b0};

endmodule

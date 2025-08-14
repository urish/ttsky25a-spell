// SPDX-FileCopyrightText: © 2021-2024 Uri Shaked <uri@wokwi.com>
// SPDX-License-Identifier: MIT

`default_nettype none

module spell_mem_internal (
    input wire rst_n,
    input wire clk,
    input wire select,
    input wire [7:0] addr,
    input wire [7:0] data_in,
    input wire memory_type_data,
    input wire write,
    output wire [7:0] data_out,
    output reg data_ready
);

  reg mem_ready;
  wire we = select && write;
  reg [8:0] mem_init_addr;
  wire mem_init_running = ~mem_ready;

  parameter CODE_MEM_INIT_VALUE = 8'b11111111;
  parameter DATA_MEM_INIT_VALUE = 8'b00000000;

  sram22_512x8m8w1 sram_macro (
      .clk(clk),
      .rstb(rst_n),
      .ce(1'b1),
      .we(we | mem_init_running),
      .wmask(8'b11111111),
      .addr(mem_ready ? {memory_type_data, addr} : mem_init_addr),
      .din(mem_ready ? data_in : mem_init_addr[8] ? DATA_MEM_INIT_VALUE: CODE_MEM_INIT_VALUE),
      .dout(data_out)
  );

  reg [1:0] cycles;

  integer i;

  always @(posedge clk) begin
    if (~rst_n) begin
      cycles <= 0;
      data_ready <= 0;
      mem_ready <= 0;
      mem_init_addr <= 0;
    end else begin
      if (!mem_ready) begin
        mem_init_addr <= mem_init_addr + 1;
        if (mem_init_addr == 9'b111111111) begin
          mem_ready <= 1;
        end
      end else if (!select) begin
        data_ready <= 1'b0;
`ifdef SPELL_INTERNAL_MEM_DELAY
        cycles <= 2'b11;
`endif  /* SPELL_INTERNAL_MEM_DELAY */
      end else if (cycles > 0) begin
        cycles <= cycles - 1;
      end else begin
        data_ready <= 1'b1;
      end
    end
  end
endmodule

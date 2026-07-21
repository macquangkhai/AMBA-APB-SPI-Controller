module spi_apb_top (
    // 1. APB System Clock & Reset
    input wire PCLK,
    input wire PRESETn,

    // 2. AMBA APB Bus Interface
    input wire [31:0] PADDR,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PWDATA,
    output wire [31:0] PRDATA,
    output wire PREADY,

    // 3. Physical SPI Interface Pins (Pads)
    output wire sck,
    output wire cs_n,
    output wire mosi,
    input wire miso
);

    // Internal Interconnect Signals between APB Bridge and SPI Master Core
    wire start;
    wire [7:0] tx_data;
    wire [7:0] rx_data;
    wire ready;
    wire [7:0] clk_div;

    // Instantiate APB Slave Interface Bridge
    spi_apb_bridge u_apb_bridge (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ready(ready),
        .clk_div(clk_div)
    );

    // Instantiate SPI Master Core
    spi_master u_spi_master (
        .clk(PCLK),
        .rst_n(PRESETn),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .ready(ready),
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .clk_div(clk_div)
    );

endmodule
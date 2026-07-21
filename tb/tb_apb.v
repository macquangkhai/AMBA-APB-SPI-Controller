`timescale 1ns/1ns

module tb_apb;

    // APB System Clock & Reset
    reg PCLK;
    reg PRESETn;

    // AMBA APB Bus Interface Signals
    reg [31:0] PADDR;
    reg PSEL;
    reg PENABLE;
    reg PWRITE;
    reg [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire PREADY;

    // Physical SPI Bus Lines
    wire sck;
    wire cs_n;
    wire mosi;
    wire miso;

    // Slave Interface Signals
    reg [7:0] slave_tx_data;
    wire [7:0] slave_rx_data;
    wire slave_rx_valid;

    // 1. Instantiate Top-Level APB SPI IP Core
    spi_apb_top u_spi_apb_top (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso)
    );

    // 2. Instantiate SPI Slave Core
    spi_slave u_slave (
        .sck(sck),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .slave_tx_data(slave_tx_data),
        .slave_rx_data(slave_rx_data),
        .slave_rx_valid(slave_rx_valid)
    );

    // Generate 50MHz APB Clock (20ns Period)
    initial PCLK = 0;
    always #10 PCLK = ~PCLK;

    // --- APB Write Transfer Task ---
    task apb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge PCLK);
            PADDR   = addr;
            PWRITE  = 1'b1; // Write Transfer
            PSEL    = 1'b1; // Select Peripheral
            PENABLE = 1'b0; // Setup Phase

            @(posedge PCLK);
            PENABLE = 1'b1; // Access Phase
            PWDATA  = data;

            @(posedge PCLK);
            PSEL    = 1'b0; // Release Bus
            PENABLE = 1'b0;
        end
    endtask

    // --- APB Read Transfer Task ---
    task apb_read;
        input [31:0] addr;
        output [31:0] rdata;
        begin
            @(posedge PCLK);
            PADDR   = addr;
            PWRITE  = 1'b0; // Read Transfer
            PSEL    = 1'b1; // Select Peripheral
            PENABLE = 1'b0; // Setup Phase

            @(posedge PCLK);
            PENABLE = 1'b1; // Access Phase

            @(posedge PCLK);
            rdata   = PRDATA; // Sample read data from PRDATA
            PSEL    = 1'b0; // Release Bus
            PENABLE = 1'b0;
        end
    endtask

    reg [31:0] temp_rdata;

    // Main APB Test Sequence
    initial begin
        // Initial Values
        PRESETn = 1'b0;
        PADDR = 32'd0;
        PSEL = 1'b0;
        PENABLE = 1'b0;
        PWRITE = 1'b0;
        PWDATA = 32'd0;
        slave_tx_data = 8'h00;

        // Assert Reset for 100ns
        #100;
        PRESETn = 1'b1;
        #50;

        // Step 1: Configure and verify clk_div
        $display("[TB] Step 1: Configuring clk_div = 6...");
        apb_write(32'h0000_0010, 32'd6); // Write 6 to CFG_REG (0x10)
        #20;
        apb_read(32'h0000_0010, temp_rdata); // Read back CFG_REG
        $display("[TB] Read back CFG_REG: 32'h%h (Expected: 6)", temp_rdata);

        // Step 2: Load transmit data for Master and Slave
        $display("[TB] Step 2: Loading transmit data...");
        apb_write(32'h0000_0008, 32'hA5); // Write 8'hA5 to TX_REG (0x08)
        slave_tx_data = 8'h5A;            // Slave preloads 8'h5A
        #20;
        apb_read(32'h0000_0008, temp_rdata); // Read back TX_REG
        $display("[TB] Read back TX_REG: 32'h%h (Expected: A5)", temp_rdata);

        // Step 3: Trigger start pulse
        $display("[TB] Step 3: Triggering start pulse...");
        apb_write(32'h0000_0000, 32'd1);  // Write 1 to CTRL_REG (0x00) to start

        // Step 4: CPU Polling READY status flag
        $display("[TB] Step 4: CPU Polling READY status...");
        temp_rdata = 32'd0;
        while (temp_rdata[0] == 1'b0) begin
            // Read STATUS_REG (0x04) continuously
            apb_read(32'h0000_0004, temp_rdata);
            #40; // Poll delay
        end
        $display("[TB] SPI Master idle detected (READY = 1)!");

        // Step 5: CPU reads received data
        $display("[TB] Step 5: CPU reading received data...");
        apb_read(32'h0000_000C, temp_rdata); // Read RX_REG (0x0C)
        $display("[TB] CPU read from SPI RX: 8'h%h (Expected: 5A)", temp_rdata[7:0]);
        $display("[TB] Slave received from Master: 8'h%h (Expected: A5)", slave_rx_data);

        #100;
        $display("[TB] APB Simulation completed successfully!");
        $finish;
    end

    // Dump VCD waveform file
    initial begin
        $dumpfile("spi_apb_tb.vcd");
        $dumpvars(0, tb_apb);
    end

endmodule
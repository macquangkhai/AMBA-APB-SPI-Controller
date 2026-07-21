module spi_apb_bridge (
    // 1. APB System Clock & Reset
    input wire PCLK,
    input wire PRESETn,

    // 2. AMBA APB Slave Bus Interface
    input wire [31:0] PADDR,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output wire PREADY,

    // 3. Control Interface to SPI Master Core
    output reg start,         // Master trigger pulse
    output reg [7:0] tx_data, // Transmit data for Master
    input wire [7:0] rx_data, // Received data from Master
    input wire ready,         // Master status (1=Ready, 0=Busy)
    output reg [7:0] clk_div  // Clock divider ratio for Master
);

    // PREADY tied high (zero wait state transfers)
    assign PREADY = 1'b1;

    // 1. APB Register Offset Definitions
    localparam ADDR_CTRL   = 5'h00; // Control Register (Bit 0: Start)
    localparam ADDR_STATUS = 5'h04; // Status Register (Bit 0: Ready)
    localparam ADDR_TX     = 5'h08; // Transmit Data Register
    localparam ADDR_RX     = 5'h0C; // Receive Data Register
    localparam ADDR_CFG    = 5'h10; // Clock Divider Configuration Register

    // APB Write Transfer Strobe
    wire apb_write;
    assign apb_write = PSEL && PENABLE && PWRITE && PREADY;

    // 2. APB Write Transfer Logic (Synchronous to PCLK)
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            start   <= 1'b0;
            tx_data <= 8'h00;
            clk_div <= 8'h04; // Default divider ratio = 4
        end
        else begin
            // Default start pulse duration: single clock cycle
            start <= 1'b0;

            if (apb_write) begin
                case (PADDR[4:0])
                    ADDR_CTRL: begin
                        start <= PWDATA[0]; // CPU writes 1 to trigger start pulse
                    end
                    ADDR_TX: begin
                        tx_data <= PWDATA[7:0]; // Load transmit data
                    end
                    ADDR_CFG: begin
                        clk_div <= PWDATA[7:0]; // Dynamically update clock divider
                    end
                    default: ; // Ignore invalid register address
                endcase
            end
        end
    end

    // 3. APB Read Transfer Logic (Combinational)
    // Provides immediate register read data to host CPU
    always @(*) begin
        // Output read data only during APB Read cycle (PSEL = 1, PWRITE = 0)
        if (PSEL && !PWRITE) begin
            case (PADDR[4:0])
                ADDR_CTRL:   PRDATA = {31'd0, start};   // Return Start bit status (1 bit)
                ADDR_STATUS: PRDATA = {31'd0, ready};   // Return READY status (1 bit: 1=Idle, 0=Busy)
                ADDR_TX:     PRDATA = {24'd0, tx_data}; // Return stored TX data (8 bits)
                ADDR_RX:     PRDATA = {24'd0, rx_data}; // Return received RX data (8 bits)
                ADDR_CFG:    PRDATA = {24'd0, clk_div}; // Return clock divider ratio (8 bits)
                default:     PRDATA = 32'd0;            // Default zero for invalid address
            endcase
        end
        else begin
            PRDATA = 32'd0; // Drive zero when not reading to avoid bus noise
        end
    end

endmodule
# AMBA APB-to-SPI Controller IP Core (Verilog HDL)

![Language](https://img.shields.io/badge/Language-Verilog%20HDL-blue)
![Bus Interface](https://img.shields.io/badge/Bus%20Interface-AMBA%203%20APB-orange)
![Toolchain](https://img.shields.io/badge/EDA-QuestaSim%20%7C%20ModelSim-green)
![Status](https://img.shields.io/badge/Status-Verified-success)

An **AMBA APB (Advanced Peripheral Bus) Compliant SPI Controller IP Core** designed in Verilog HDL for SoC (System-on-Chip) peripheral integration. The IP features a full 32-bit APB Slave Interface bridge (`spi_apb_bridge`), dynamic clock scaling prescaler, and CPU status polling capabilities.

---

## Key Features

### 1. AMBA APB Slave Bus Protocol Compliance
* Fully compliant with 32-bit AMBA APB specification handling **Setup Phase** (`PSEL=1, PENABLE=0`) and **Access Phase** (`PSEL=1, PENABLE=1`).
* Zero-wait-state transfers (`PREADY = 1`).

### 2. Memory-Mapped Register File (32-bit)
* Provides memory-mapped control, status, data transmit/receive, and clock configuration registers accessible by the host CPU via APB bus transfers.

### 3. Dynamic Clock Prescaler
* Integrated dynamic clock divider ratio (`clk_div`) in the SPI Master core, runtime-configurable via APB Configuration Register (`CFG_REG`).

### 4. Status Polling & Busy Flag
* Host CPU can poll the `READY` bit in `STATUS_REG` over the APB bus to detect transaction completion before reading received data from `RX_REG`.

---

## APB Memory Map & Register Definitions

| Offset Address | Register Name | Access Type | Reset Value | Description |
| :---: | :---: | :---: | :---: | :--- |
| `0x00` | `CTRL_REG` | Write / Read | `0x00000000` | **Control Register:** Write `1` to Bit 0 (`start`) to trigger an 8-bit transaction. Auto-clears upon execution. |
| `0x04` | `STATUS_REG` | Read-only | `0x00000001` | **Status Register:** Bit 0 (`ready`). `1` = Idle/Ready, `0` = SPI Master Busy. |
| `0x08` | `TX_REG` | Write / Read | `0x00000000` | **Transmit Data Register:** Lower 8 bits (`[7:0]`) contain data to be transmitted over MOSI. |
| `0x0C` | `RX_REG` | Read-only | `0x00000000` | **Receive Data Register:** Lower 8 bits (`[7:0]`) contain data received from MISO. |
| `0x10` | `CFG_REG` | Write / Read | `0x00000004` | **Clock Config Register:** Lower 8 bits (`[7:0]`) specify the clock divider ratio (`clk_div`). Default = 4. |

---

## 📐 System Architecture

```mermaid
graph LR
    subgraph "Host System"
        CPU["Host CPU / Bus Master"]
    end

    subgraph "AMBA APB SPI IP Core (Top)"
        APB_Bridge["APB Slave Bridge<br/>spi_apb_bridge.v"]
        Master["SPI Master Core<br/>spi_master.v"]
    end

    subgraph "SPI Peripheral"
        Slave["SPI Slave Core<br/>spi_slave.v"]
    end

    CPU -- "APB Bus<br/>PCLK, PADDR, PWDATA, PRDATA, PSEL, PENABLE, PWRITE" --> APB_Bridge
    APB_Bridge -- "Control / Data / clk_div" --> Master
    Master -- "Physical Bus<br/>SCK, CS_n, MOSI, MISO" --> Slave
```

---

## Verification & Waveform Results

The testbench (`tb/tb_apb.v`) simulates host CPU APB register write/read tasks and status polling loops.

![APB SPI Waveform](docs/apb_spi_transaction_waveform.png)

### Verification Steps Demonstrated:
1. **Clock Divider Config:** APB Write `6` to `CFG_REG` (`0x10`), verified by APB Read returning `6`.
2. **Tx Data Load:** APB Write `0xA5` to `TX_REG` (`0x08`), verified by APB Read returning `0xA5`.
3. **Trigger Transaction:** APB Write `1` to `CTRL_REG` (`0x00`) to pulse `start`.
4. **CPU Status Polling:** CPU repeatedly reads `STATUS_REG` (`0x04`) until `READY = 1`.
5. **Rx Data Read:** APB Read from `RX_REG` (`0x0C`) returns `0x5A` received from SPI Slave.

---

## How to Run Simulation

### Prerequisites
* EDA Tool: QuestaSim / ModelSim (Intel FPGA Edition or standard).

### Steps:
1. Open **QuestaSim / ModelSim**.
2. Change directory to the `sim/` folder:
   ```tcl
   cd "sim"
   ```
3. Run the TCL simulation script:
   ```tcl
   do run.tcl
   ```

---

## Repository Structure

```text
AMBA-APB-SPI-Controller/
├── README.md                      # Project documentation
├── .gitignore                     # Git ignore rules for EDA build outputs
├── docs/                          # Waveform screenshots
│   └── apb_spi_transaction_waveform.png
├── rtl/                           # Verilog HDL RTL source files
│   ├── SPI_apb_top.v              # Top-level Wrapper integrating APB Bridge & SPI Master
│   ├── SPI_apb_bridge.v           # AMBA APB Slave Interface Bridge & Register File
│   ├── SPI_Master.v               # SPI Master Core
│   └── SPI_Slave.v                # SPI Slave Core (Verification Model)
├── tb/                            # Verification Testbench
│   └── tb_apb.v                   # APB Bus Transfer Testbench
└── sim/                           # Simulation Scripts
    └── run.tcl                    # QuestaSim TCL script
```

---

## 👤 Author

* **Role:** RTL Design & Verification

<h3>Contact Me</h3>
<p>
  <a href="[https://github.com/macquangkhai](https://github.com/macquangkhai)">
    <img src="https://img.shields.io/badge/GitHub-MacQuangKhai-181717?style=for-the-badge&logo=github&logoColor=white"/>
  </a>
  
  <a href="mailto:khaimac616@gmail.com">
    <img src="https://img.shields.io/badge/Gmail-khaimac616%40gmail.com-EA4335?style=for-the-badge&logo=gmail&logoColor=white"/>
  </a>
</p>

# ==============================================================================
# run_apb.tcl - Script chạy mô phỏng hệ thống SPI APB trên Questa Sim / ModelSim
# ==============================================================================

# 1. Khởi tạo thư viện làm việc (work library)
if [file exists work] {
    vdel -all
}
vlib work
vmap work work

# 2. Biên dịch các tệp nguồn Verilog
echo "========================================="
echo "   BAT DAU BIEN DICH CAC FILE VERILOG    "
echo "========================================="
vlog -work work ../rtl/SPI_Master.v
vlog -work work ../rtl/SPI_Slave.v
vlog -work work ../rtl/SPI_apb_bridge.v
vlog -work work ../rtl/SPI_apb_top.v
vlog -work work ../tb/tb_apb.v

# 3. Khởi chạy mô phỏng module testbench (tb_apb)
vsim -voptargs="+acc" work.tb_apb

# 4. Thêm các tín hiệu cần quan sát vào cửa sổ Waveform
echo "========================================="
echo "       CAU HINH DUONG SONG (WAVE)        "
echo "========================================="
add wave -divider "APB BUS CONTROL"
add wave -color "cyan"   -position insertpoint sim:/tb_apb/PCLK
add wave -color "red"    -position insertpoint sim:/tb_apb/PRESETn
add wave -hex -position insertpoint sim:/tb_apb/PADDR
add wave -position insertpoint sim:/tb_apb/PSEL
add wave -position insertpoint sim:/tb_apb/PENABLE
add wave -position insertpoint sim:/tb_apb/PWRITE
add wave -hex -position insertpoint sim:/tb_apb/PWDATA
add wave -hex -position insertpoint sim:/tb_apb/PRDATA
add wave -position insertpoint sim:/tb_apb/PREADY

add wave -divider "SPI PHYSICAL BUS"
add wave -color "yellow" -position insertpoint sim:/tb_apb/cs_n
add wave -color "cyan"   -position insertpoint sim:/tb_apb/sck
add wave -color "green"  -position insertpoint sim:/tb_apb/mosi
add wave -color "orange" -position insertpoint sim:/tb_apb/miso

add wave -divider "BRIDGE REGISTERS"
add wave -hex -position insertpoint sim:/tb_apb/u_spi_apb_top/u_apb_bridge/start
add wave -hex -position insertpoint sim:/tb_apb/u_spi_apb_top/u_apb_bridge/tx_data
add wave -hex -position insertpoint sim:/tb_apb/u_spi_apb_top/u_apb_bridge/rx_data
add wave -hex -position insertpoint sim:/tb_apb/u_spi_apb_top/u_apb_bridge/clk_div

add wave -divider "MASTER INTERNAL REGISTERS"
add wave -position insertpoint sim:/tb_apb/u_spi_apb_top/u_spi_master/state
add wave -radix unsigned -position insertpoint sim:/tb_apb/u_spi_apb_top/u_spi_master/clk_cnt
add wave -radix unsigned -position insertpoint sim:/tb_apb/u_spi_apb_top/u_spi_master/bit_cnt
add wave -hex -position insertpoint sim:/tb_apb/u_spi_apb_top/u_spi_master/tx_shifter
add wave -hex -position insertpoint sim:/tb_apb/u_spi_apb_top/u_spi_master/rx_shifter

add wave -divider "SLAVE INTERNAL REGISTERS"
add wave -hex -position insertpoint sim:/tb_apb/u_slave/slave_tx_data
add wave -hex -position insertpoint sim:/tb_apb/u_slave/slave_rx_data
add wave -position insertpoint sim:/tb_apb/u_slave/slave_rx_valid
add wave -radix unsigned -position insertpoint sim:/tb_apb/u_slave/bit_cnt

# 5. Chạy mô phỏng toàn bộ kịch bản
echo "========================================="
echo "         BAT DAU CHAY MO PHONG           "
echo "========================================="
run -all

# Zoom vừa vặn màn hình dạng sóng
wave zoom full

# ==============================================================================
# run.tcl - Script tối ưu cho chụp ảnh Hình 2.4 (Setup & Access Phase APB)
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

# 4. Thêm ĐÚNG các tín hiệu cần thiết cho Hình 2.4 (Giao diện APB & Thanh ghi thực thi)
echo "========================================="
echo "       CAU HINH DUONG SONG TINH GON      "
echo "========================================="
add wave -divider "AMBA APB PROTOCOL SIGNALS"
add wave -color "cyan"   -position insertpoint sim:/tb_apb/PCLK
add wave -color "red"    -position insertpoint sim:/tb_apb/PRESETn
add wave -hex -position insertpoint sim:/tb_apb/PADDR
add wave -color "yellow" -position insertpoint sim:/tb_apb/PSEL
add wave -color "green"  -position insertpoint sim:/tb_apb/PENABLE
add wave -position insertpoint sim:/tb_apb/PWRITE
add wave -hex -position insertpoint sim:/tb_apb/PWDATA
add wave -position insertpoint sim:/tb_apb/PREADY

add wave -divider "INTERNAL REGISTER EXECUTION"
add wave -hex -color "orange" -position insertpoint sim:/tb_apb/u_spi_apb_top/u_apb_bridge/clk_div

# 5. Chạy mô phỏng toàn bộ kịch bản
echo "========================================="
echo "         BAT DAU CHAY MO PHONG           "
echo "========================================="
run -all

# 6. Zoom căn chỉnh chuẩn mốc thời gian Setup Phase (150ns-170ns) và Access Phase (170ns-190ns)
wave zoomrange 140ns 200ns

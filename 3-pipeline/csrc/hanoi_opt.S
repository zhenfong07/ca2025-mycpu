.text
.global _start

_start:
    # --- 1. INIT STACK POINTER (QUAN TRỌNG) ---
    # Đặt SP tại 0x2000 (Vùng an toàn cho RAM nhỏ)
    li      sp, 0x02000   

    # --- 2. SETUP TRAP HANDLER ---
    # Bắt buộc phải làm trước khi gọi ecall
    la      t0, trap_vector
    csrw    mtvec, t0

    # --- PROLOGUE ---
    addi    x2, x2, -32
    sw      x8,  0(x2)
    sw      x9,  4(x2)
    sw      x18, 8(x2)
    sw      x19, 12(x2)

    # Init Disk counts
    sw      x0, 16(x2)
    sw      x0, 20(x2)
    sw      x0, 24(x2)

    li      x8, 1            # x8 bắt đầu từ 1
    addi    x4, x0, 8        # Điều kiện dừng là 8

game_loop:
    beq     x8, x4, finish_game

    # --- GRAY CODE LOGIC (Optimized) ---
    srli    x5, x8, 1
    addi    x7, x8, -1       # Lệnh chèn
    xor     x6, x8, x5

    srli    x28, x7, 1
    xor     x7, x7, x28
    xor     x5, x6, x7

    # --- FIND DISK ---
    addi    x9, x0, 0
    andi    x6, x5, 1
    bne     x6, x0, disk_found
    
    addi    x9, x0, 1
    andi    x6, x5, 2
    bne     x6, x0, disk_found
    
    addi    x9, x0, 2

disk_found:
    slli    x5, x9, 2
    addi    x5, x5, 16
    add     x5, x2, x5
    lw      x18, 0(x5)       # LOAD
    
    bne     x9, x0, handle_large  # Lệnh chèn (tránh Stall)

    addi    x19, x18, 2      # USE
    li      x6, 3
    blt     x19, x6, update_state
    sub     x19, x19, x6
    jal     x0, update_state

handle_large:
    lw      x6, 16(x2)
    li      x19, 3
    sub     x19, x19, x18
    sub     x19, x19, x6

update_state:
    slli    x5, x9, 2
    addi    x5, x5, 16
    add     x5, x2, x5
    sw      x19, 0(x5)

    # --- 3. TEST ECALL ---
    # Gọi ecall để kiểm tra Trap Handler
    ecall

    addi    x8, x8, 1        # Tăng biến đếm
    jal     x0, game_loop

finish_game:
    # --- EPILOGUE ---
    # lw      x8,  0(x2)     <-- COMMENT DÒNG NÀY (Giữ kết quả x8 = 8)
    lw      x9,  4(x2)
    lw      x18, 8(x2)
    lw      x19, 12(x2)
    addi    x2, x2, 32

    # Vòng lặp vô tận
finish_loop:
    jal     x0, finish_loop

# --- 4. HÀM XỬ LÝ NGẮT (TRAP HANDLER) ---
.align 4
trap_vector:
    # Lưu thanh ghi tạm
    addi    sp, sp, -4
    sw      t0, 0(sp)

    # Đọc địa chỉ lệnh gây lỗi (ecall)
    csrr    t0, mepc
    
    # Tăng PC lên 4 để bỏ qua lệnh ecall
    addi    t0, t0, 0
    
    # Ghi lại PC mới
    csrw    mepc, t0

    # Khôi phục thanh ghi tạm
    lw      t0, 0(sp)
    addi    sp, sp, 4

    # Quay về chạy tiếp (Return from Trap)
    mret
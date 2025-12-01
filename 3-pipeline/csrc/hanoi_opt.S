.text
.global _start

_start:
    # Initial stack 
       li      sp, 0x02000   

    # setup trap handler
    
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

    li      x8, 1            # x8 start from 1
    addi    x4, x0, 8        # stop at 8

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
    
    bne     x9, x0, handle_large  #Insert to avoid Stall operation
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
        ecall

    addi    x8, x8, 1        
    jal     x0, game_loop

finish_game:
    lw      x9,  4(x2)
    lw      x18, 8(x2)
    lw      x19, 12(x2)
    addi    x2, x2, 32

   
finish_loop:
    jal     x0, finish_loop

#  (TRAP HANDLER) ---
.align 4
trap_vector:
    # Lưu thanh ghi tạm
    addi    sp, sp, -4
    sw      t0, 0(sp)

    # (ecall)
    csrr    t0, mepc
    csrw    mepc, t0
    lw      t0, 0(sp)
    addi    sp, sp, 4

   
    mret
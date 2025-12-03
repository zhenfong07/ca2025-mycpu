.text
.global _start

_start:
    # --- INIT ---
    li      sp, 0x02000         # Initialize Stack Pointer
    la      t0, trap_vector
    csrw    mtvec, t0           # Setup Trap Vector Base Address

    # --- PROLOGUE ---
    addi    x2, x2, -32
    sw      x8,  0(x2)
    sw      x9,  4(x2)
    sw      x18, 8(x2)
    sw      x19, 12(x2)
    
    # Init Disk positions (0,0,0)
    sw      x0, 16(x2)
    sw      x0, 20(x2)
    sw      x0, 24(x2)

    # --- PRE-LOAD CONSTANTS (Invariant Code Motion) ---
    li      x8, 1               # Counter start
    li      x4, 8               # Loop limit (Kept in x4)
    li      x20, 3              # Constant 3 (Used for peg calculation)

game_loop:
    #  Use x4 directly, remove redundant 'addi x5'
    beq     x8, x4, finish_game

    # --- GRAY CODE LOGIC ---
    srli    x5, x8, 1
    addi    x7, x8, -1
    xor     x6, x8, x5

    srli    x28, x7, 1
    xor     x7, x7, x28
    xor     x5, x6, x7

    # --- FIND DISK ---
    # Disk finding logic remains unchanged as it is data-dependent
    andi    x6, x5, 1
    addi    x9, x0, 0
    #andi    x6, x5, 1
    bne     x6, x0, disk_found
    
    andi    x6, x5, 2
    addi    x9, x0, 1
    #andi    x6, x5, 2
    bne     x6, x0, disk_found
    
    addi    x9, x0, 2

disk_found:
    slli    x5, x9, 2
    addi    x5, x5, 16
    add     x5, x2, x5
    lw      x18, 0(x5)          # LOAD disk position

    
    # Hazard Fix: Inserted Branch to avoid Load-Use Stall
    bne     x9, x0, handle_large

 
    addi    x19, x18, 2
    lw x6,16(x2)
    blt     x19, x20, update_state  # Compare with x20
    sub     x19, x19, x20           # Subtract x20
    jal     x0, update_state

handle_large:
    lw      x6, 16(x2)
    #  Use x20 (value 3) instead of 'li x19, 3'
    sub     x19, x20, x18       # 3 - current
    sub     x19, x19, x6        # result - other

update_state:
    slli    x5, x9, 2
    addi    x5, x5, 16
    add     x5, x2, x5
    sw      x19, 0(x5)          # Store new position

    # --- Trap Test ---
    ecall

    addi    x8, x8, 1           # Increment Counter
    jal     x0, game_loop

finish_game:
   
    lw      x9,  4(x2)
    lw      x18, 8(x2)
    lw      x19, 12(x2)
    addi    x2, x2, 32

finish_loop:
    jal     x0, finish_loop

# --- TRAP HANDLER ---
.align 4
trap_vector:
    addi    sp, sp, -4
    sw      t0, 0(sp)
    csrr    t0, mepc
    
    csrw    mepc, t0
    lw      t0, 0(sp)
    addi    sp, sp, 4
    mret
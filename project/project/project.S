.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:

    # set up PMP so all of memory is accessible and we don't trap when entering supervisor mode
    csrw pmpcfg0, 0x0000000F //set pmpconfig to 00001111 or F
    li t0, 0xFFFFFFFF
    csrw pmpaddr0, t0
    # Define region 0 to cover all addresses as RWX
    #nop

    # switch to supervisor mode	
    csrr t0, mstatus
    li t1, 0x1800
    not t2, t1
    and t0, t0, t2
    li t2, 0x0800
    or t0, t0, t2
    csrw mstatus, t0
    # Set mstatus.MPP to 01, set MEPC to a trampoline address where supervisor should begin, do mret
    # Set mepc to supervisorstart

    mret                      # enter supervisor mode at supervisorstart
    #nop

supervisorstart:
    la t0, pagetable          # get address of root page table
    csrw satp, t0              # enable virtual memory

    # now we are executing on virtual page 0x80000, which is also physical page 0x80000
    # (this can be whatever you want as long as you use the correct address defined in the proj)	
    li t0, 0x90000300       
    li t1, 42
    sw t1, 0(t0)

    la t0, testcode           # address of a routine to run
    lui t1, 0x10000         
    add t0, t0, t1            # address of testcode on virtual page 0x90000 
    jr t0                    # jump to the testcode on Virtual page 0x90000, 
                              # which still points to same code on physical page 0x80000
    nop                      # shouldn't be executed

testcode:
    li t0, 42                # do something

write_tohost:
    la s1, tohost             # terminate with write tohost
    li t0, 1                  # 1 for success, 3 for failure
    sw t0, 0(s1)              # send success code (yay)
    sw zero, 4(s1)            # not obvious why Sail isn't terminating unless this write is done

self_loop:
    j self_loop

tohost:
    .word 0

.data

.align 16
# root (L1) Page table situated at 0x80010000
pagetable:


.align 12
# L0 page table situated at 0x80011000

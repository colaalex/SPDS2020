# сумма арифметической прогрессии (количество членов – 25, разность арифметической прогрессии – 7)

# v0 = 0
# t0 = 0
# s0 = 25
# while s0 != 0:
# t0 += 7
# v0 += t0
# s0 -= 1

        .text

init:   li      $v0, 0          ## v0 = 0   // результат
        li      $t0, 0          ## t0 = 0   // текущий член прогрессии
        li      $s0, 25         ## s0 = 25
        li      $s1, 1          ## s1 = 1   // константа, так как у нас нет операции subiu

loop:   addu    $v0, $v0, $t0   ## v0 += t0
        addiu   $t0, $t0, 7     ## t0 += 7
        subu    $s0, $s0, $s1   ## s0 -= s1 // s0 -= 1
        bne     $s0, $0, loop   ## (while) s0 != 0

end:    b       end             ## while True
		li	$t1, 0
init:		li	$t0, 0		# Flag of swap
		li	$a0, 16		# Number of Elements, n
		li	$a1, 1
start:		li	$t2, 1		# j = 1
for1:		li	$t0, 0		# f = 0
		li	$t1, 0x0	# Beginning of Data
		subu	$t3, $a0, $t2	# i_end = n-j
		li	$t4, 0
for2:		lw	$t5, 0($t1)	# a[i]
		lw	$t6, 1($t1)	# a[i+1]
		sltu	$t7, $t5, $t6
		beq	$t7, $a1, no_swap
		sw	$t5, 1($t1)	# a[i+1] = a[i]
		sw	$t6, 0($t1)	# a[i] = a[i+1]
		li 	$t0, 1		# f = 1
no_swap:	addiu 	$t1, $t1, 1	#address+=1
		addiu 	$t4, $t4, 1	# i++
		bne	$t4, $t3, for2
		beqz	$t0, end	# if f = 0 exit for
		addiu	$t2, $t2, 1
		bne	$t2, $a0, for1 	# if j < n-1
end:		beqz	$0, end
		

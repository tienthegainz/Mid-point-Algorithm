.eqv KEY_CODE 0xFFFF0004  # ASCII code to show, 1 byte 
.eqv KEY_READY 0xFFFF0000        # =1 if has a new keycode ?                                  
				# Auto clear after lw 
.eqv DISPLAY_CODE 0xFFFF000C # ASCII code to show, 1 byte 
.eqv DISPLAY_READY 0xFFFF0008  # =1 if the display has already to do                                  
				# Auto clear after sw 

.data
L :	.asciiz "a"
R : 	.asciiz "d"
U: 	.asciiz "w"
D: 	.asciiz "s"
.text	
	li $k0, KEY_CODE 	# chua ki tu nhap vao
	li $k1, KEY_READY	# kiem tra da nhap phim nao chua  
	li $s2, DISPLAY_CODE	# hien thi ky tu  
	li $s1, DISPLAY_READY	# kiem tra xem man hinh da san sang hien thi chua
	
	addi	$s7, $0, 512			#store the width in s7 CONSTANT
	#Khoi tao cac gia tri cua hinh tron:
	addi	$a0, $0, 256		#x = 256
	addi	$a1, $0, 256		#y = 256	
	addi	$a2, $0, 20		#r = 20
	addi 	$s0, $0, 0x00FFFF66
	jal 	DrawCircle	
	nop
Input:
	ReadKey: lw $t0, 0($k0) # $t0 = [$k0] = KEY_CODE
moving:
	# Kiem tra phim nao duoc bam
	beq $t0,97,left
	nop
	beq $t0,100,right
	nop
	beq $t0,115,down
	nop
	beq $t0,119,up
	nop
	j Input
	nop
	left:
		addi $s0,$0,0x00000000
		jal DrawCircle #Ve lai hinh tron mau den
		nop
		addi $a0,$a0,-3
		add $a1,$a1, $0
		addi $s0,$0,0x00FFFF66
		jal DrawCircle # Ve hinh tron o vi tri moi
		nop
		jal Pause
		nop
		bltu $a0,20,reboundRight #Cham vao thanh khung hinh
		j Input
		nop
	right: 
		addi $s0,$0,0x00000000
		jal DrawCircle
		nop
		addi $a0,$a0,3
		add $a1,$a1, $0
		addi $s0,$0,0x00FFFF66
		jal DrawCircle
		nop
		jal Pause
		nop
		bgtu $a0,492,reboundLeft
		j Input
		nop
	up: 
		addi $s0,$0,0x00000000
		jal DrawCircle
		nop
		addi $a1,$a1,-3
		add $a0,$a0,$0
		addi $s0,$0,0x00FFFF66
		jal DrawCircle
		nop
		jal Pause
		nop
		bltu $a1,20,reboundDown	
		j Input
		nop
	down: 
		addi $s0,$0,0x00000000
		jal DrawCircle
		nop
		addi $a1,$a1,3
		add $a0,$a0,$0
		addi $s0,$0,0x00FFFF66
		jal DrawCircle
		nop
		jal Pause
		nop
		bgtu $a1,492,reboundUp	
		j Input
		nop
	reboundLeft:
		li $t3 97 #Dua ki tu cua phim a vao $t3
		sw $t3,0($k0) #Nap vao dinh stack
		j Input
		nop
	reboundRight:
		li $t3 100
		sw $t3,0($k0)
		j Input
		nop
	reboundDown:
		li $t3 115
		sw $t3,0($k0)
		j Input
		nop
	reboundUp:
		li $t3 119
		sw $t3,0($k0)
		j Input
		nop
		
Pause:
	addiu $sp,$sp,-4
	sw $a0, ($sp)
	la $a0,20		# sleep=20ms
	li $v0, 32	 #syscall value for sleep
	syscall
	lw $a0,($sp)
	addiu $sp,$sp,4
	jr $ra
DrawCircle:

	###Mid-point algorithm
	###Params###
	#a0 = cx
	#a1 = cy
	#a2 = radius
	#s0 = colour
	
	addiu	$sp, $sp, -32 #Luu cac bien vao stack
	sw 	$ra, 28($sp)
	sw	$a0, 24($sp)
	sw	$a1, 20($sp)
	sw	$a2, 16($sp)
	sw	$s4, 12($sp)
	sw	$s3, 8($sp)
	sw	$s2, 4($sp)
	sw	$s0, ($sp)
	
	#code goes here
	sub	$s2, $0, $a2			#error =  -radius
	add	$s3, $0, $a2			#x = radius
	add	$s4, $0, $0			#y = 0 
	
	DrawCircleLoop:
	bgt 	$s4, $s3, exitDrawCircle	#y>x?KET THUC:VE TIEP
	nop
	
	jal	plot8points
	nop
	
	#cap nhat diem giua
	add	$s2, $s2, $s4			
	addi	$s4, $s4, 1			
	add	$s2, $s2, $s4			#error +=2y+1
	
	blt	$s2, 0, DrawCircleLoop		#if error >= 0, start loop again
	nop
	
	sub	$s3, $s3, 1			
	sub	$s2, $s2, $s3			
	sub	$s2, $s2, $s3			#error -=2x+2
	
	j	DrawCircleLoop
	nop	
	
	exitDrawCircle:
	# tra lai cac bien
	lw	$s0, ($sp)
	lw	$s2, 4($sp)
	lw	$s3, 8($sp)
	lw	$s4, 12($sp)
	lw	$a2, 16($sp)
	lw	$a1, 20($sp)
	lw	$a0, 24($sp)
	lw	$ra, 28($sp)
	
	addiu	$sp, $sp, 32
	
	jr 	$ra
	nop
	
plot8points:
	# Ve ra 8 diem tren hinh tron
	addiu	$sp, $sp -4
	sw	$ra, ($sp)
	
	jal	plot4points
	nop
	
	beq 	$s4, $s3, skipSecondplot # Neu x=y thi khong can swap x va y
	nop
	
	#swap y and x, and do it again
	add	$t2, $0, $s4			#puts y into t2
	add	$s4, $0, $s3			#puts x in to y
	add	$s3, $0, $t2			#puts y in to x
	
	jal	plot4points
	nop
	
	#swap them back
	add	$t2, $0, $s4			#puts y into t2
	add	$s4, $0, $s3			#puts x in to y
	add	$s3, $0, $t2			#puts y in to x
		
	skipSecondplot:
		
	lw	$ra, ($sp)
	addiu	$sp, $sp, 4
	
	jr	$ra
	nop
	
plot4points:
	#Ve ra 4 diem
	addiu	$sp, $sp -4
	sw	$ra, ($sp)
	
	#$a0 = a0 + s3, $a2 = a1 + s4
	add	$t0, $0, $a0			#store a0 (cx in t0)
	add	$t1, $0, $a1			#store a2 (cy in t1)
	
	add	$a0, $t0, $s3			#set a0 (x for the setpixel, to cx + x)
	add	$a2, $t1, $s4			#set a2 (y for setPixel to cy + y)
	
	jal	SetPixel			#draw the first pixel
	nop
	
	sub	$a0, $t0, $s3			#cx - x
	
	beq	$s3, $0, skipXnotequal0 	#if s3 (x) equals 0, skip
	nop
	
	jal 	SetPixel			#if x!=0 (cx - x, cy + y)
	nop	

	skipXnotequal0:	
	sub	$a2, $t1, $s4			#cy - y (a0 already equals cx - x)
	jal 	SetPixel			#no if	 (cx - x, cy - y)
	nop
	
	add	$a0, $t0, $s3			#cx+x
	
	beq	$s4, $0, skipYnotequal0 	#if s4 (y) equals 0, skip
	nop
	
	jal	SetPixel			#if y!=0 (cx + x, cy - y)
	nop
	
	skipYnotequal0:
	
	add	$a0, $0, $t0			
	add	$a2, $0, $t1			
	
	lw	$ra, ($sp)
	addiu	$sp, $sp, 4
	
	jr	$ra
	nop
SetPixel:
	#a0 x
	#a1 y
	#s0 colour
	addiu	$sp, $sp, -20			# Save return address on stack
	sw	$ra, 16($sp)
	sw	$s1, 12($sp)
	sw	$s0, 8($sp)			# Save original values of a0, s0, a2
	sw	$a0, 4($sp)
	sw	$a2, ($sp)

	lui	$s1, 0x1004			#starting address of the screen	
	#lui	$s1, 0x1000			# out of range error
	sll	$a0, $a0, 2 			#multiply 4
	add	$s1, $s1, $a0			#x co-ord addded to pixel position
	mul  	$a2, $a2, $s7			#multiply by width 
	sll	$a2, $a2, 2			#myltiply by the size of the pixels (4)
	add	$s1, $s1, $a2			#add y co-ord to pixel position

	sw	$s0, ($s1)			#stores the value of colour into the pixels memory address
	
	lw	$a2, ($sp)			#retrieve original values and return address
	lw	$a0, 4($sp)
	lw	$s0, 8($sp)
	lw	$s1, 12($sp)
	lw	$ra, 16($sp)
	addiu	$sp, $sp, 20	
	
	jr	$ra
	nop
	

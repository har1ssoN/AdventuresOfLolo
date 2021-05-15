.data
.text
#################################
#				#
#	    PRINT		#
#				#
#################################

.macro print_background(%label)
	li t1,0xFF000000	# endereco inicial da Memoria VGA - Frame 0
	li t2,0xFF012C00	# endereco final - Frame 0
	li t3,0
	bgtz  t0, SOMA_PB
	j INICIO_PB
SOMA_PB:
	li t0, 0x00100000
	add t1,t1,t0		# Endereço Inicial - Frame 1 - 0xFF100000
	add t2,t2,t0		# Endereço Final - Frame 1 - 0xFF112C00
INICIO_PB:
	 
	la s1,%label		# endereço dos dados da tela na memoria
	addi s1,s1,8		# primeiro pixels depois das informações de nlin ncol
LOOP1_PB: beq t1,t2,FIM_PB	# Se for o último endereço então sai do loop
	lw t3,0(s1)		# le um conjunto de 4 pixels : word
	sw t3,0(t1)		# escreve a word na memória VGA
	addi t1,t1,4		# soma 4 ao endereço
	addi s1,s1,4
	j LOOP1_PB		# volta a verificar
FIM_PB:

.end_macro

#################################
#				#
# 	   Frames		#
#				#
#################################

.macro change_frame()
	li s0,0xFF200604	# Escolhe o Frame 0 ou 1
	lw t2,0(s0)		# inicio Frame
	xori t2, t2, 1
	sw t2,0(s0)
.end_macro

.macro frame_atual()
	li s0, 0xFF200604
	lw t0, 0(s0)
.end_macro

.macro next_frame()
	li s0, 0xFF200604
	lw t2, 0(s0)
	xori t0, t2,1
.end_macro
	

#################################
#				#
#	Carrega valores		#
#   pra usar no PRINT_IMAGE	#
#				#
#################################

.macro load_values(%x,%y,%label)
li s2, %x
li s1, %y
la a1, %label
.end_macro

#################################
#				#
#	   Verifica		#
#   o caractere da KEYBOARD 	#
#				#
#################################

.macro verify(%char,%label)
li t1, %char
beq t1,t0,%label
.end_macro


#################################
#				#
# 	     CLEAN		#
#				#
#################################


.macro clean_image(%label)
mv s2, t1
mv s1, t2
la a1, %label
.end_macro


#################################
#				#
#	   MOVEMENTS		#
#				#
#################################

# Armazena X em t1, e Y em t2



.macro load_position(%label)
la a0, %label
lh t1, 0(a0)
lh t2, 2(a0)
.end_macro

.macro movement_y_up(%label)
addi s1,t2, -16
sh s1, 2(a0)
mv s2, t1
la a1,%label
.end_macro

.macro movement_y_down(%label)
addi s1,t2, 16
sh s1, 2(a0)
mv s2, t1
la a1,%label
.end_macro

.macro movement_x_left(%label)
addi s2,t1, -16
sh s2, 0(a0)
mv s1, t2
la a1, %label
.end_macro

.macro movement_x_right(%label)
addi s2,t1, 16
sh s2, 0(a0)
mv s1, t2
la a1, %label
.end_macro

#################################
#				#
#				#
#	   COLISÃO		#
#				#
#				#
#################################

.macro verifica_muro(%label)
la a2, MURO
lh t4, 2(a2)
lh t5, 6(a2)
lh t6, 0(a2)
lh s4, 4(a2)
blt s1,t4,%label
bgt s1,t5,%label
blt s2,t6,%label
bgt s2,s4,%label
.end_macro


#################################
#				#
#     Colis�o de Blocos		#
# Borda Lateral = 71 (preto)	#
# Borda Superior = 24 (muro)	#
# Pixels = 16			#
# (X atual - Borda Lat.)/16     #
# (Y atual - Borda Sup.)/16     #
# 	Y*11 + X		#
#				#
#################################

# t0, s2,s1, a1
# Armazena em s7 o bloco atual
.macro bloco_atual()
li s7, 0
li s8, 71
li s9, 24
li s10, 16
li s11, 11
la a5, POSITION
lh s6, 0(a5)	# X
lh s4, 2(a5)	# Y
sub s6, s6, s8
sub s4, s4, s9
div s6, s6, s10
div s4, s4, s10
mul s7, s4, s11
add s7, s7, s6
.end_macro

# t0, s2,s1, a1
.macro verifica_bloco(%label, %condicional)
la a5, %label
add a5, a5, s7
lb t5, 0(a5)		# Bloco do Mapa que a Sprite está
la a2, BLOCOS_BLOQUEADOS
li t6, 11		# Tamanho dos BLOCOS_BLOQUEADOS
li s4, 0		# Contador
LOOP:
	beq s4, t6, FIM
	addi s4, s4, 1
	lb s6, 0(a2)
	beq t5, s6, %condicional
	addi a2, a2, 1
	j LOOP
FIM:

.end_macro

.macro conta_pokebola(%label, %fase)
la a6, NUM_POKEBOLA
lb a5, %fase(a6)
la s8, %label
add s8, s8, s7
lb t5, 0(s8)
li s6, 20 
beq t5, s6, SOMA
j FIM

SOMA: 
	la s9, POKEBOLA
	lb s10, 0(s9)
	addi s10, s10, 1
	sb s10, 0(s9)

FIM:    
	
.end_macro

#################################
#				#
#   Verifica a �ltima tecla, 	#
#    se for igual, printa	#
#   uma sprite diferente,	#
#     usando um contador	#
#      que diferencia		#
#      (�mpar ou par)		#
#				#
#################################

.macro ultima_tecla(%label)
la a2,CONTADOR
lw t3, 0(a2)	# Carrega o contador
addi t3,t3,1	# Contador+=1
sw t3, 0(a2)	# Atualiza o Contador 
li t4, 2
rem t0,t3,t4
beqz t0, %label
.end_macro

#################################
#				#
#	Carrega a label		#
#	e a frame para usar	#
#	no procedimento		#
#	PRINT_MAPA		#
#				#
#################################

.macro load_fase(%label)
la a0, %label
.end_macro

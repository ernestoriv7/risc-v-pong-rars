#All rights reserved
#Copyright belongs to Ernesto Rivera
#You can use this code freely in your project(s) as long as credit is given :)

#Inspiration taken from a MIPS assembly version done by: https://github.com/AndrewHamm/MIPS-Pong for the 
#MARS emulator

#The official repository of the RARS emulator can be found in: https://github.com/TheThirdOne/rars

# To run the project:
# 1) In the upper bar go to Run->Assemble (f3)
# 2) In the upper bar go to Tools->Bitmap Display
# 3) Configure the following settings in in the Bitmap Display:
	# a) Unit Width: 8
	# b) Unit Height: 8
	# c) Display Width: 512
	# d) Display Height: 256
	# e) Base Address: gp
	# f) Press connect to program 
# 4) In the upper bar go to Tools->Keyboard and Display MMIO Simulator and press connect to MIPS
# 5) In the upper bar go to Run->Go (f5)
# 6) Click on the lower window of the Keyboard and Display simulator to produce inputs

#Player movement is w and s for the left player and o and l for the right player.

#FOR THE STUDENTS: Internal labels of a function starts with a .

# Here I define the constants that will be used along the code
.eqv TOTAL_PIXELS, 8192 # The total ammount of pixels in the screen
.eqv FOUR_BYTES, 4 # The displacement in memory is done words which equals four bytes

.eqv TITLE_SCREEN_FIRST_LINE_ROW_Y, 1
.eqv TITLE_SCREEN_SECOND_LINE_ROW_Y, 12

.eqv PONG_TEXT_X, 21
.eqv PONG_TEXT_Y, 5
.eqv PONG_TEXT_H, 5

.eqv PRESS_TEXT_X, 12
.eqv PRESS_TEXT_Y, 16
.eqv PRESS_TEXT_H, 4

.eqv NAME_TEXT_X 4
.eqv NAME_TEXT_Y 24
.eqv NAME_TEXT_H, 4

.eqv KEY_INPUT_ADDRESS 0xFFFF0004
.eqv KEY_STATUS_ADDRESS 0xFFFF0000
# For reference of those addreses check https://www.it.uu.se/education/course/homepage/os/vt18/module-1/memory-mapped-io/

.eqv ASCII_1 0x00000031
.eqv ASCII_2 0x00000032

.eqv MOV_UP 1
.eqv MOV_DOWN 2
.eqv MOV_STAY 0

.eqv INITIAL_PADDLE_POSITION 13

.eqv INITIAL_BALL_X_POS 32
.eqv INITIAL_BALL_Y_POS 0

.eqv SCORE_FIRST_ROW_POINTS 5
.eqv SCORE_SECOND_ROW_POINTS 6
.eqv ROW_1 1
.eqv ROW_3 3
.eqv P1_SCORE_COLUMN 1
.eqv P2_SCORE_COLUMN 54
.eqv GAME_WIN_POINTS 10

.eqv PADDLE_LENGTH 5

.eqv TOP_PADDLE_Y_ROW 0
.eqv BOTTOM_PADDLE_Y_ROW 26 #  31 - 5 = 26 Thats the lowest point that paddle y can reach

.eqv PLAYER_1_PADDLE_X_POS 13
.eqv PLAYER_2_PADDLE_X_POS 50

.eqv FIRST_COLUMN 0
.eqv LAST_COLUMN 63

.eqv BALL_RIGHT_DIR 1
.eqv BALL_LEFT_DIR -1
.eqv BALL_UP_DIR -1
.eqv BALL_DOWN_DIR 1

.eqv BALL_Y_VELOCITY_REDUCTION -1

.eqv LEFT_COLLISION_X_POS 14
.eqv RIGHT_COLLISION_X_POS 49

# The constants for the ball-pallet collision position
.eqv TOP_HIGH 0
.eqv TOP_MID 1
.eqv TOP_LOW 2
.eqv BOTTOM_HIGH 3
.eqv BOTTOM_MID 4
.eqv BOTTOM_LOW 5

# The horizontal wall limists
.eqv Y_DOWN_LIMIT 31
.eqv Y_UP_LIMIT 0

.eqv Y_MAX_COLLISION_VELOCITY 1

# Player modes
.eqv ONE_PLAYER_MODE 1
.eqv TWO_PLAYER_MODE 2


# ASSCII characters

.eqv ASCII_W 119
.eqv ASCII_S 115
.eqv ASCII_O 111
.eqv ASCII_L 108

# The coordinmates of the end game screen

.eqv P_CHAR_WIN_X 26
.eqv P_CHAR_WIN_Y 5
.eqv P_CHAR_WIN_H 5

.eqv PLAYER_NUM_WIN_X 33
.eqv PLAYER_NUM_WIN_Y 5
.eqv PLAYER_NUM_WIN_H 5

.eqv WINS_TEXT_X, 21
.eqv WINS_TEXT_Y, 16
.eqv WINS_TEXT_H, 5

 # Begin of the data section
.data
	color_white:	.word 0x00ffffff
	color_black:	.word 0x00000000
	color_red:		.word 0x00ff0000
	color_cyan: 	.word 0x0000ffff
	color_orange:	.word 0x00ffa500
	
	player_mode:	.word 0
		
	ball_x_dir:			.word BALL_RIGHT_DIR	    # The ball starts going right
	ball_y_speed:		.word -1	# The wait steps before moving in the y axis
	ball_y_dir:			.word -1	# The ball starts going down
	p1_score:		.word 0
	p2_score: 		.word 0
	computer_count:	.word 0
	computer_speed:	.word 0		#Used after first collision
	level:			.word 6		
	
	
.text

new_game:
	
	jal clear_board
	jal draw_title_screen
	
	select_1_or_2_players:
    	lw t0, KEY_INPUT_ADDRESS # Verify if the player pressed an input
    	li t1, ASCII_1
    	beq t0, t1, one_player_mode
    	li t1, ASCII_2
    	beq	t0, t1, two_player_mode
    	
    	li a0, 250
    	li a7, 32
    	ecall
    	
    	j select_1_or_2_players # If a key was not pressed go back to the loop
    	
    one_player_mode:
    	li t0, 1
    	sw t0, player_mode, t1
    	j start_game
    
    two_player_mode:
    	li t0, 2
    	sw t0, player_mode, t1
    	j start_game
    	
    start_game:
    	sw zero, KEY_STATUS_ADDRESS, t0 # This clears the status if a key was pressed
    
    j new_round	

    	
# Function: new_round
#	The function does not have parameters, but due to speed internally uses the following convention
#		s0 stores the p1 dir
#		s1 stores the p2 dir
#		s2 stores thel ball x velocity
#		s3 stores the ball y velocity
#		s4 stores the player 1 paddle position
#		s5 stores the player 2 paddle position
#		s6 stores the ball x position
# 		s7 stores tghe ball y position
# This function is part of the main loop, so it does not require to save the state of the s registers
# but if it were an internal function, it should save each state.
new_round:
	#Initialize of the required register state for  the new round
	li t0, 1
	sw t0, ball_y_speed, t1
	li t0, -1
	sw t0, ball_y_dir, t1
	sw zero, computer_speed, t1
	sw zero, computer_count, t1
	
	li s0, MOV_STAY
	li s1, MOV_STAY
	lw s2, ball_x_dir
	lw s3, ball_y_speed
	li s4, INITIAL_PADDLE_POSITION
	li s5, INITIAL_PADDLE_POSITION
	li s6, INITIAL_BALL_X_POS
	li s7, INITIAL_BALL_Y_POS
	
	jal clear_board

	lw a0, p1_score
	li a1, P1_SCORE_COLUMN
	jal draw_score
	
	lw a0, p2_score
	li a1, P2_SCORE_COLUMN
	jal draw_score
	
	li a0, PLAYER_1_PADDLE_X_POS
	mv a1, s4
	lw a2, color_red
	li a3, MOV_STAY
	jal	draw_paddle
	
	li a0, PLAYER_2_PADDLE_X_POS 
	mv a1, s5
	lw a2, color_red
	li a3, MOV_STAY
	jal draw_paddle
	
	li a0, 1000
	li a7, 32		
	ecall		# 1 second delay

	j main_game_loop

# Function: main_game_loop
# This function is the main game loop of the game when playing
#	The function does not have parameters, but due to speed internally uses the following conventions
#		s0 stores the p1 dir
#		s1 stores the p2 dir
#		s2 stores thel ball x velocity
#		s3 stores the ball y velocity
#		s4 stores the player 1 paddle position
#		s5 stores the player 2 paddle position
#		s6 stores the ball x position
# 		s7 stores the ball y position
# Return:
# 	void.
main_game_loop:
	.draw_objects:
		jal check_collisions
		jal move_ball
		
		li a0, PLAYER_1_PADDLE_X_POS
		mv a1, s4
		lw a2, color_red
		mv a3, s0
		jal draw_paddle
		mv s4, a0
		mv s0, a1
	
	.start_ai:
		lw t0, player_mode
		li t1, ONE_PLAYER_MODE
		bne t0, t1, .end_ai
		
		lw  t0, computer_count
		addi t0, t0, -1
		sw t0, computer_count, t1
		bgt t0 , zero, .end_ai # as long as computer cound is > 0, perform ai
		lw t0, computer_speed
		sw t0, computer_count, t1
		addi t1, s5, 2 	# Calculate the middle of the paddle
		blt t1, s7, .go_down
		li s1, MOV_UP
		j .end_ai
		
	.go_down:
		li s1, MOV_DOWN
		
	.end_ai:
		li a0, PLAYER_2_PADDLE_X_POS
		mv a1, s5
		lw a2, color_red
		mv a3, s1
		jal draw_paddle
		mv s5, a0
		mv s1, a1

# Wait and read inputs
	.begin_standby:
		li t0, 2 # A counter is loaded for an aprox 50ms delay
	
	.standby:
		blez t0, .end_standby
		
		# syscall for pausing 10 ms
		li a0, 10
		li a7, 32
		ecall		
	
		addi t0, t0, -1
		
		# check for a key press
		lw t1, KEY_STATUS_ADDRESS
		blez t1, .standby
		
		jal adjust_dir
		sw zero, KEY_STATUS_ADDRESS, t1 # Clean the state that a key has been pressed
		#j .standby
		
	.end_standby:
		j .draw_objects
# Function: adjust_dir
# Parameters:
#	None.
# Return:
#	void.
adjust_dir:
	lw t0, KEY_INPUT_ADDRESS
	
	.adjust_dir_left_up:
		li t1, ASCII_W
		bne t0, t1, .adjust_dir_left_down
		li s0, MOV_UP
		j .adjust_dir_done
	
	.adjust_dir_left_down:
		li t1, ASCII_S
		bne t0, t1, .adjust_dir_right_up
		li s0, MOV_DOWN
		j .adjust_dir_done
	
	.adjust_dir_right_up:
		li t1, ASCII_O
		bne t0, t1, .adjust_dir_right_down
		li s1, MOV_UP
		j .adjust_dir_done
		
	.adjust_dir_right_down:
		li t1, ASCII_L
		bne t0, t1, .adjust_dir_none
		li s1, MOV_DOWN
		j .adjust_dir_done
		
	.adjust_dir_none:
		# This section is kept as a case point if the player didn't press a valid option
	
	.adjust_dir_done:
		jr ra
		
#FunctionL check_collisions
# Parameters:
#	a0: ball x pos
#	a1: ball Y pos
# Return: 
#	void.
check_collisions:
	# First check if a player is losing a point
	li t0, FIRST_COLUMN
	beq s6, t0, p1_loses_round
	li t0, LAST_COLUMN
	beq s6, t0, p2_loses_round
	
	li t0, LEFT_COLLISION_X_POS
	beq s6, t0, .left_collision
	
	li t0, RIGHT_COLLISION_X_POS
	beq s6, t0, .right_collision
	
	j .no_paddle_collision
	
	.left_collision:
		# Check if ball is above pallet
		blt s7, s4, .no_paddle_collision
		# Check if ball is below pallet
		addi t0, s4, PADDLE_LENGTH #Calculating the pallet bottom position
		bgt s7, t0, .no_paddle_collision
		li s2, BALL_RIGHT_DIR
		j .paddle_hit
		
	
	.right_collision:
		blt s7, s5, .no_paddle_collision
		li t0, PADDLE_LENGTH
		add t0, s5, t0
		bgt s7, t0, .no_paddle_collision
		sub t0, s7, s5		#Distance from top to hit
		li s2, BALL_LEFT_DIR #Change ball direction
		j .paddle_hit
		
	.no_paddle_collision:
	
		j .check_horizontal_hit

	.paddle_hit:
	# Make the sound when the ball hits the paddle
		li a0, 80
		li a1, 80
		li a2, 32
		li a3, 127
		li a7, 31
		ecall
	#Adjust the computer speed to avoid missing the first ball
		lw t0, level
		sw t0, computer_speed, t1
	
	# Get the difference between the ball and the pallet
		sub t0, s7, s4
		li t1, TOP_HIGH
		beq t0, t1, .top_high
		li t1, TOP_MID
		beq t0, t1, .top_mid
		li t1, TOP_LOW
		beq t0, t1, .top_low
		li t1, BOTTOM_HIGH
		beq t0, t1, .bottom_high
		li t1, BOTTOM_MID
		beq t0, t1, .bottom_mid
		li t1, BOTTOM_LOW
		beq t0, t1, .bottom_low
	
	.top_high:
		li s3, TOP_HIGH
		sw s3, ball_y_speed, t0
		li s3, BALL_UP_DIR
		sw s3, ball_y_dir, t0
		j .check_horizontal_hit
	
	.top_mid:
		li s3, TOP_MID
		sw s3, ball_y_speed, t0
		li s3, BALL_UP_DIR
		sw s3, ball_y_dir, t0
		j .check_horizontal_hit
	
	.top_low:
		li s3, TOP_LOW
		sw s3, ball_y_speed, t0
		li s3, BALL_UP_DIR
		sw s3, ball_y_dir, t0
		j .check_horizontal_hit
	
	.bottom_high:
		li s3, BOTTOM_HIGH
		sw s3, ball_y_speed, t0
		li s3, BALL_DOWN_DIR
		sw s3, ball_y_dir, t0
		j .check_horizontal_hit
	
	.bottom_mid:
		li s3, BOTTOM_MID
		sw s3, ball_y_speed, t0
		li s3, BALL_DOWN_DIR
		sw s3, ball_y_dir, t0
		j .check_horizontal_hit
	
	.bottom_low:
		li s3, BOTTOM_LOW
		sw s3, ball_y_speed, t0
		li s3, BALL_DOWN_DIR
		sw s3, ball_y_dir, t0
		j .check_horizontal_hit
	
	.check_horizontal_hit:
		li t0, Y_DOWN_LIMIT
		beq s7, t0, .horizontal_wall_hit
		li t0, Y_UP_LIMIT
		bne s7, t0, .no_collision
	
	
	.horizontal_wall_hit:
		li t0, Y_MAX_COLLISION_VELOCITY
		bgt s3, t0, .no_collision
		lw t0, ball_y_dir
		not t1, zero
		xor t0, t0, t1
		addi t0, t0, 1
		sw t0, ball_y_dir, t1
		
	.no_collision:
		jr ra
	
# Function: move_ball
# Paramenters:
#	The function does not have parameters, but due to speed internally uses the following conventions
#		s0 stores the p1 dir
#		s1 stores the p2 dir
#		s2 stores thel ball x velocity
#		s3 stores the ball y velocity
#		s4 stores the player 1 paddle position
#		s5 stores the player 2 paddle position
#		s6 stores the ball x position
# 		s7 stores the ball y position
# Return:
# 	void.
move_ball:
	addi sp, sp -4
	sw ra, 0(sp)
	
	mv a0, s6
	mv a1, s7
	lw a2, color_black
	jal draw_point
	
	add s6, s6, s2 # add the x speed to the x coordinate
	li t0, BALL_Y_VELOCITY_REDUCTION
	add s3, s3, t0
	bgt s3, zero, .no_y_change
	
	.change_y:
		lw t0, ball_y_dir
		add s7, s7, t0
		lw s3, ball_y_speed
	
	.no_y_change:
		mv a0, s6
		mv a1, s7	
		lw a2, color_white
		jal draw_point
			
	lw ra, 0(sp)
	addi sp, sp, 4
	jr ra
	
p1_loses_round:
	# Incremente player 2's score
	lw t0, p2_score
	addi t0, t0, 1
	sw t0, p2_score, t1
		
	# Set up the next round
	li t0, BALL_RIGHT_DIR
	sw t0, ball_x_dir, t1
	jal clear_key_press
	
	lw t0, p2_score
	li t1, GAME_WIN_POINTS
	beq t0, t1, end_game
	
	j play_point_sound
	
p2_loses_round:
	#Incremente player 1's score
	lw t0, p1_score
	addi t0, t0, 1
	sw t0, p1_score, t1
	
	# Set  up the next round
	li t0, BALL_LEFT_DIR
	sw t0, ball_x_dir, t1
	jal clear_key_press
		
	lw t0, p1_score
	li t1, GAME_WIN_POINTS
	beq t0 ,t1, end_game
		
	j play_point_sound
	
play_point_sound:
	# Plays a sound when a player scores
	li a0, 80
	li a1, 300
	li a2, 121
	li a3, 127
	li a7, 31
	ecall
	
	j new_round
		
	
end_game:
	jal clear_board

	lw t0, p1_score
	li t1, GAME_WIN_POINTS
	bne t0, t1, .player_2_wins
	
	.player_1_wins:
		li a0, PLAYER_NUM_WIN_X
		li a1, PLAYER_NUM_WIN_Y
		addi a1, a1, 1
		lw a2, color_white
		jal draw_point
		
		li a0, PLAYER_NUM_WIN_X
		addi a0, a0, 1
		li a1, PLAYER_NUM_WIN_Y
		lw a2, color_white
		li a3, PLAYER_NUM_WIN_Y
		addi a3, a3, PLAYER_NUM_WIN_H
		jal draw_vertical_line
		
		li a0, PLAYER_NUM_WIN_X
		li a1, PLAYER_NUM_WIN_Y
		addi a1, a1, PLAYER_NUM_WIN_H
		lw a2, color_white
		addi a3, a0, 2
		jal draw_horizontal_line
		j .win_p
		
	.player_2_wins:
		li a0, PLAYER_NUM_WIN_X
		li a1, PLAYER_NUM_WIN_Y
		addi a1, a1, 1
		lw a2, color_white
		jal draw_point
		
		li a0, PLAYER_NUM_WIN_X
		addi a0, a0, 1
		li a1, PLAYER_NUM_WIN_Y
		lw a2, color_white
		addi a3, a0, 2
		jal draw_horizontal_line
		
		li a0, PLAYER_NUM_WIN_X
		addi a0, a0, 4
		li a1, PLAYER_NUM_WIN_Y
		addi a1, a1, 1
		lw a2, color_white
		jal draw_point
				
		li a0, PLAYER_NUM_WIN_X
		addi a0, a0, 3
		li a1, PLAYER_NUM_WIN_Y
		addi a1, a1, 2
		lw a2, color_white
		jal draw_point
		
		li a0, PLAYER_NUM_WIN_X
		addi a0, a0, 2
		li a1, PLAYER_NUM_WIN_Y
		addi a1, a1, 3
		lw a2, color_white
		jal draw_point
		
		li a0, PLAYER_NUM_WIN_X
		addi a0, a0, 1
		li a1, PLAYER_NUM_WIN_Y
		addi a1, a1, 4
		lw a2, color_white
		jal draw_point
		
		li a0, PLAYER_NUM_WIN_X
		li a1, PLAYER_NUM_WIN_Y
		addi a1, a1, PLAYER_NUM_WIN_H
		lw a2, color_white
		addi a3, a0, 4
		jal draw_horizontal_line
		
		j .win_p
	.win_p:
	# The P
		li a0, P_CHAR_WIN_X
		li a1, P_CHAR_WIN_Y
		lw a2, color_white
		li a3, P_CHAR_WIN_Y
		addi a3, a3, P_CHAR_WIN_H
		jal draw_vertical_line
	
		li a0, P_CHAR_WIN_X
		addi a0, a0, 4
		li a1, P_CHAR_WIN_Y
		addi a1, a1, 1
		lw a2, color_white
		addi a3, a1, 2
		jal draw_vertical_line
	
		li a0, P_CHAR_WIN_X
		addi a0, a0, 1
		li a1, P_CHAR_WIN_Y
		addi a1, a1, 3
		lw a2, color_white
		addi a3, a0, 2
		jal draw_horizontal_line
	
		li a0, P_CHAR_WIN_X
		addi a0, a0, 1
		li a1, P_CHAR_WIN_Y
		lw a2, color_white
		addi a3, a0, 3
		jal draw_horizontal_line
	
	.wins:
	# The W
		li a0, WINS_TEXT_X
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a1, 2
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, 1
		li a1, WINS_TEXT_Y
		addi a1, a1, 3
		lw a2, color_white
		addi a3, a1, 1
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, 2
		li a1, WINS_TEXT_Y
		addi a1, a1, WINS_TEXT_H
		lw a2, color_white
		jal draw_point
		
		li a0, WINS_TEXT_X
		addi a0, a0, 3
		li a1, WINS_TEXT_Y
		addi a1, a1, 3
		lw a2, color_white
		addi a3, a1, 1
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, 4
		li a1, WINS_TEXT_Y
		addi a1, a1, WINS_TEXT_H
		lw a2, color_white
		jal draw_point
		
		li a0, WINS_TEXT_X
		addi a0, a0, 5
		li a1, WINS_TEXT_Y
		addi a1, a1, 3
		lw a2, color_white
		addi a3, a1, 1
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, 6
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a1, 2
		jal draw_vertical_line
		
	# The I starts at offset 8
.eqv I_OFFSET 8
		li a0, WINS_TEXT_X
		addi a0, a0, I_OFFSET
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a0, 4 
		jal draw_horizontal_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, I_OFFSET
		addi a0, a0, 2
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a1, WINS_TEXT_H
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, I_OFFSET
		li a1, WINS_TEXT_Y
		addi a1, a1, WINS_TEXT_H
		lw a2, color_white
		addi a3, a0, 4 
		jal draw_horizontal_line
	
		# The N starts at offset 14
.eqv N_OFFSET 14

		li a0, WINS_TEXT_X
		addi a0, a0, N_OFFSET
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a1, WINS_TEXT_H
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, N_OFFSET
		addi a0, a0, 1
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a1, 1
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, N_OFFSET
		addi a0, a0, 2
		li a1, WINS_TEXT_Y
		addi a1, a1, 2
		lw a2, color_white
		addi a3, a1, 1
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, N_OFFSET
		addi a0, a0, 3
		li a1, WINS_TEXT_Y
		addi a1, a1, 4
		lw a2, color_white
		addi a3, a1, 1
		jal draw_vertical_line

		li a0, WINS_TEXT_X
		addi a0, a0, N_OFFSET
		addi a0, a0, 4
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a1, WINS_TEXT_H
		jal draw_vertical_line
		
		#The S starts at offset 20
.eqv S_OFFSET 20
		li a0, WINS_TEXT_X
		addi a0, a0, S_OFFSET
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a0, 4
		jal draw_horizontal_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, S_OFFSET
		li a1, WINS_TEXT_Y
		lw a2, color_white
		addi a3, a1, 1
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, S_OFFSET
		li a1, WINS_TEXT_Y
		addi a1, a1, 2
		lw a2, color_white
		addi a3, a0, 2
		jal draw_horizontal_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, S_OFFSET
		addi a0, a0, 2
		li a1, WINS_TEXT_Y
		addi a1, a1, 3
		lw a2, color_white
		addi a3, a0, 1
		jal draw_horizontal_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, S_OFFSET
		addi a0, a0, 4
		li a1, WINS_TEXT_Y
		addi a1, a1, 3
		lw a2, color_white
		addi a3, a1, 2
		jal draw_vertical_line
		
		li a0, WINS_TEXT_X
		addi a0, a0, S_OFFSET
		li a1, WINS_TEXT_Y
		addi a1, a1, WINS_TEXT_H
		lw a2, color_white
		addi a3, a0, 4
		jal draw_horizontal_line

	.pause:
		li a0, 3000
		li a7, 32	
		ecall		#Pause for 100 milisec
		
	jal clear_key_status
	
	.reset_wait:
		li a0, 10
		li a7, 32 
		ecall		#Pause for 100 milisec
		
		li t0, KEY_STATUS_ADDRESS
		beq t0, zero, .reset_wait
		
		j .reset
	
	.reset:
		sw zero, p1_score, t0
		sw zero, p2_score, t0
		jal clear_key_status
		jal clear_key_press
		
		jal clear_board
		
		j new_game
	
	

# Function: draw_paddle
# Parameters:
#	a0: paddle x position
#	a1: paddle top y position
#	a2: paddle color
#	a3: paddle direction
# Return:
#	a0: new top y position
#	a1: direction of the paddle
draw_paddle:
	addi sp, sp -20
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	sw s3, 16(sp)

	mv s0, a0
	mv s1, a1
	mv s2, a2
	mv s3, a3

	li t0, MOV_STAY
	beq t0, s3, .no_mov
	li t0, MOV_DOWN
	beq t0, s3, .down
	
	#The default case is the up movement
	
	.up: 
		#erase bottom point
		mv a0, s0
		mv a1, s1 
		addi a1, a1, PADDLE_LENGTH
		lw a2, color_black
		jal draw_point
		
		li t0, TOP_PADDLE_Y_ROW
		beq s1, t0, .no_mov
		addi s1, s1, -1
		j .move
			
	.down:
		#erase top point
		mv a0, s0
		mv a1, s1
		lw a2, color_black
		jal draw_point
		
		li t0, BOTTOM_PADDLE_Y_ROW
		beq s1, t0, .no_mov
		addi s1, s1, 1
		j .move
	
	.no_mov:
		#set the return value to MOV_STAY
		li s3, MOV_STAY
	
	.move:
		mv a0, s0
		mv a1, s1
		mv a2, s2
		li t0, PADDLE_LENGTH
		add a3, a1, t0
		jal draw_vertical_line
	# The return values of the new y-top position
	mv a0, s1
	mv a1, s3

	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	lw s3, 16(sp)
	addi sp, sp 20
	
	jr ra

# Function: draw_score
# Parameters:
#	a0: score of the player
#	a1: column of the leftmost scoring dot
# Return:
#	void
draw_score:
	addi sp, sp, -16
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw a0, 12(sp)
	
	mv s0, a0
	mv s1, a1
	li t0, SCORE_FIRST_ROW_POINTS
	ble s0, t0, .score_row_1
	
	.score_row_2:
	li  t0, SCORE_SECOND_ROW_POINTS
	sub t0, s0, t0
	li t1, 1
	sll t0, t0, t1
	add a0, t0, s1 
	li a1, ROW_3
	lw a2, color_white 
	jal draw_point
	
	addi s0, s0, -1
	li t0, SCORE_SECOND_ROW_POINTS
	bge s0, t0, .score_row_2
	
	.score_row_1:
	beq s0, zero, .score_end
	addi t0, s0, -1
	li t1, 1 # I put the number here directly without label because its use is evident
	sll t0, t0, t1
	add a0, t0, s1 
	li a1, ROW_1
	lw a2, color_white 
	jal draw_point
	
	addi s0, s0, -1
	j .score_row_1
	
	.score_end:
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw a0, 12(sp)
	addi sp, sp, 16
	
	jr ra
	
		
# Function: draw_point
# Parameters:
#	a0: x coordinate
#	a1: y coordinate
#	a2: color of the point
# Return
#	void
draw_point:
	li t0, 6
	sll t0, a1, t0 #Due to the size of the screen, multiply y coodinate by 64 (length of the field)
	add t1, a0, t0
	li t0, 2
	sll t1, t1, t0 # Multiply the resulting coodinate by 4
	add t1, t1, gp
	sw a2, (t1)
	jr ra
	

# Function: draw_horizontal_line
# Parameters:
#	a0: starting x coordinate
#	a1: y coordinate
#	a2: color of the line
#	a3: ending x coordinate
# Return
#	void
draw_horizontal_line:
	
	addi sp, sp, -16
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	
	sub s0, a3, a0
	mv s1, a0
	li s2, 0
	
	.horizontal_loop:
		add a0, s1, s0
		jal draw_point
		addi s0, s0, -1
		
		bge s0, s2, .horizontal_loop
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	addi sp, sp, 16	
	
	jr ra

# Function: draw_vertical_line
# Parameters:
#	a0: x coordinate
#	a1: starting y coordinate
#	a2: color of the line
#	a3: ending y coordinate
# Return
#	void
draw_vertical_line:
	
	addi sp, sp, -16
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	
	sub s0, a3, a1
	mv s1, a1
	li s2, 0
	
	.vertical_loop:
		add a1, s1, s0
		jal draw_point
		addi s0, s0, -1
		
		bge s0, s2, .vertical_loop
	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	
	addi sp, sp, 16	
	
	jr ra
	
# Function: clear_board
# Parameters:
#	none
# Return
#	void
clear_board:
	lw t0, color_black
	li t1, TOTAL_PIXELS
	li t2, FOUR_BYTES
	
	.start_clear_loop:
		sub t1, t1, t2
		add t3, t1, gp
		sw t0, (t3)
		beqz t1, .end_clear_loop
		j .start_clear_loop
		
	.end_clear_loop:
	
	jr ra
	
# Function: draw_title_screen
# Parameters:
#	none
# Return
#	void
draw_title_screen:

	addi sp, sp, -4
	sw ra, 0(sp)

	# The upper lines
	li a0, 10
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	lw a2, color_red
	li a3, 53
	jal draw_horizontal_line
	
	li a0, 10
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_cyan
	li a3, 53
	jal draw_horizontal_line
	
	li a0, 10
	li a1, TITLE_SCREEN_FIRST_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_orange
	li a3, 53
	jal draw_horizontal_line
	
	# The below lines
	li a0, 10
	li a1, TITLE_SCREEN_SECOND_LINE_ROW_Y
	lw a2, color_red
	li a3, 53
	jal draw_horizontal_line
	
	li a0, 10
	li a1, TITLE_SCREEN_SECOND_LINE_ROW_Y
	addi a1, a1, 1
	lw a2, color_cyan
	li a3, 53
	jal draw_horizontal_line
	
	li a0, 10
	li a1, TITLE_SCREEN_SECOND_LINE_ROW_Y
	addi a1, a1, 2
	lw a2, color_orange
	li a3, 53
	jal draw_horizontal_line
	
	# Pong text
	# The P
	li a0, PONG_TEXT_X
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, PONG_TEXT_H
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 4
	li a1, PONG_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	addi a3, a1, 2
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 1
	li a1, PONG_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 1
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line
	
	# The O
	li a0, PONG_TEXT_X
	addi a0, a0, 6
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, PONG_TEXT_H
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 10
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, PONG_TEXT_H
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 6
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line

	li a0, PONG_TEXT_X
	addi a0, a0, 6
	li a1, PONG_TEXT_Y
	addi a1,  a1, 5
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line
			
	# The N
	li a0, PONG_TEXT_X
	addi a0, a0, 12
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, PONG_TEXT_H
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 13
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 14
	li a1, PONG_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 15
	li a1, PONG_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 16
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, PONG_TEXT_H
	jal draw_vertical_line
	
	
	#The G
	li a0, PONG_TEXT_X
	addi a0, a0, 18
	li a1, PONG_TEXT_Y
	lw a2, color_white
	li a3, PONG_TEXT_Y
	addi a3, a3, PONG_TEXT_H
	jal draw_vertical_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 19
	li a1, PONG_TEXT_Y
	addi a1, a1, 5
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 19
	li a1, PONG_TEXT_Y
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 20
	li a1, PONG_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, PONG_TEXT_X
	addi a0, a0, 22
	li a1, PONG_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point
	
	# Press 1 or 2 text
	# The P
	li a0, PRESS_TEXT_X
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 3
	li a1, PRESS_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 1
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 1
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	# The R
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 5
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 7
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 7
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_black
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 6
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 6
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
			
	#The E
	li a0, PRESS_TEXT_X
	addi a0, a0, 9
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 10
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 10
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 10
	li a1, PRESS_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point
	
	# The first S
	li a0, PRESS_TEXT_X
	addi a0, a0, 12
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 12
	li a1, PRESS_TEXT_Y
	addi a1, a1, 3
	lw a2, color_black
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 13
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 13
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 2
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 13
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 4
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 14
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line

	li a0, PRESS_TEXT_X
	addi a0, a0, 14
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 1
	lw a2, color_black
	jal draw_point

	# The other S
		
	li a0, PRESS_TEXT_X
	addi a0, a0, 16
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 16
	li a1, PRESS_TEXT_Y
	addi a1, a1, 3
	lw a2, color_black
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 17
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 17
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 2
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 17
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 4
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 18
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line

	li a0, PRESS_TEXT_X
	addi a0, a0, 18
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 1
	lw a2, color_black
	jal draw_point
	
	# The 1 

	li a0, PRESS_TEXT_X
	addi a0, a0, 23
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
			
	li a0, PRESS_TEXT_X
	addi a0, a0, 22
	li a1, PRESS_TEXT_Y
	addi a1,  a1, 1
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 22
	li a1, PRESS_TEXT_Y
	addi a1, a1, PRESS_TEXT_H
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	# The O
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 27
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line

	li a0, PRESS_TEXT_X
	addi a0, a0, 29
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line		
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 28
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 28
	li a1, PRESS_TEXT_Y
	addi a1, a1, PRESS_TEXT_H
	lw a2, color_white
	jal draw_point
	
	# The R
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 31
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 33
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 33
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_black
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 32
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 32
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	# The 2
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 36
	li a1, PRESS_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 37
	li a1, PRESS_TEXT_Y
	lw a2, color_white
	addi a3, a0, 1
	jal draw_horizontal_line	

	li a0, PRESS_TEXT_X
	addi a0, a0, 39
	li a1, PRESS_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	jal draw_point
	
	li a0, PRESS_TEXT_X
	addi a0, a0, 38
	li a1, PRESS_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 37
	li a1, PRESS_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	jal draw_point

	li a0, PRESS_TEXT_X
	addi a0, a0, 36
	li a1, PRESS_TEXT_Y
	addi a1, a1, PRESS_TEXT_H
	lw a2, color_white
	addi a3, a0, 3
	jal draw_horizontal_line
					
	# The name																																																																
																																																																																																																													
	#The E
	li a0, NAME_TEXT_X
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 1
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 1
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 1
	li a1, NAME_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point																																																																																																																																																																																							
				
	# The R
	
	li a0, NAME_TEXT_X
	addi a0, a0, 5
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 3
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 5
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_black
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 4
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, NAME_TEXT_X
	addi a0, a0, 4
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point					
	
	# The N
	
	li a0, NAME_TEXT_X
	addi a0, a0, 7
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 8
	li a1, NAME_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 9
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 10
	li a1, NAME_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 11
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	#The second E
	li a0, NAME_TEXT_X
	addi a0, a0, 13
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 14
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 14
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 14
	li a1, NAME_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point		
	
	# The S
		
	li a0, NAME_TEXT_X
	addi a0, a0, 16
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 16
	li a1, NAME_TEXT_Y
	addi a1, a1, 3
	lw a2, color_black
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 17
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 17
	li a1, NAME_TEXT_Y
	addi a1,  a1, 2
	lw a2, color_white
	jal draw_point

	li a0, NAME_TEXT_X
	addi a0, a0, 17
	li a1, NAME_TEXT_Y
	addi a1,  a1, 4
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 18
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line

	li a0, NAME_TEXT_X
	addi a0, a0, 18
	li a1, NAME_TEXT_Y
	addi a1,  a1, 1
	lw a2, color_black
	jal draw_point
	
	# The T
	li a0, NAME_TEXT_X
	addi a0, a0, 20
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 21
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	# The O
	
	li a0, NAME_TEXT_X
	addi a0, a0, 24
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line

	li a0, NAME_TEXT_X
	addi a0, a0, 26
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line		
	
	li a0, NAME_TEXT_X
	addi a0, a0, 25
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, NAME_TEXT_X
	addi a0, a0, 25
	li a1, NAME_TEXT_Y
	addi a1, a1, NAME_TEXT_H
	lw a2, color_white
	jal draw_point
	
	# The R form Rivera
	
	li a0, NAME_TEXT_X
	addi a0, a0, 32
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 30
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 32
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_black
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 31
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, NAME_TEXT_X
	addi a0, a0, 31
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	# The I
	li a0, NAME_TEXT_X
	addi a0, a0, 34
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 35
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 34
	li a1, NAME_TEXT_Y
	addi a1, a1, NAME_TEXT_H
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
	
	# The V
	li a0, NAME_TEXT_X
	addi a0, a0, 38
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 39
	li a1, NAME_TEXT_Y
	addi, a1, a1, 2
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 40
	li a1, NAME_TEXT_Y
	addi a1, a1, NAME_TEXT_H
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 41
	li a1, NAME_TEXT_Y
	addi, a1, a1, 2
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 42
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	#The second E
	li a0, NAME_TEXT_X
	addi a0, a0, 44
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, PRESS_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 45
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 45
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 45
	li a1, NAME_TEXT_Y
	addi a1, a1, 4
	lw a2, color_white
	jal draw_point		
	
	# The second R from Rivera
	
	li a0, NAME_TEXT_X
	addi a0, a0, 49
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 47
	li a1, NAME_TEXT_Y
	lw a2, color_white
	addi a3, a1, NAME_TEXT_H
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 49
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_black
	jal draw_point
	
	li a0, NAME_TEXT_X
	addi a0, a0, 48
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, NAME_TEXT_X
	addi a0, a0, 48
	li a1, NAME_TEXT_Y
	addi a1, a1, 2
	lw a2, color_white
	jal draw_point
	
	# The A
	
	li a0, NAME_TEXT_X
	addi a0, a0, 51
	li a1, NAME_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 52
	li a1, NAME_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 54
	li a1, NAME_TEXT_Y
	addi a1, a1, 1
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 55
	li a1, NAME_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	addi a3, a1, 1
	jal draw_vertical_line
	
	li a0, NAME_TEXT_X
	addi a0, a0, 53
	li a1, NAME_TEXT_Y
	lw a2, color_white
	jal draw_point

	li a0, NAME_TEXT_X
	addi a0, a0, 52
	li a1, NAME_TEXT_Y
	addi a1, a1, 3
	lw a2, color_white
	addi a3, a0, 2
	jal draw_horizontal_line
			
			
	lw ra, 0(sp)
	addi sp, sp, 4
	
	jr ra 


# Function: clear_key_press
# Parameters:
# 	none.
# Return:
#	void.
clear_key_press:
	sw zero, KEY_INPUT_ADDRESS, t0
	jr ra
	
# Function: clear_key_status
# Parameters:
# 	none.
# Return:
#	void.
clear_key_status:
	sw zero, KEY_STATUS_ADDRESS, t0
	jr ra


end:

j end

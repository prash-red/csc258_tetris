################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number (if applicable)
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    32
# - Display height in pixels:   24
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
############################################################################## 
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# The width of the tetris playing area including the borders
TETRIS_WIDTH:
    .word 16
# The height of the tetris playing area including the borders
TETRIS_HEIGHT:
    .word 24
# The location where the tetris playing area starts from (the memory address from where its starts to be drawn)
TETRIS_START:
    .word 0x10008000
# default location of the I tetromino as x, y values in an array
I_TETROMINO:
    .word 8, 1, 8, 2, 8, 3, 8, 4, 8, 2
# colour of the I tetromino
I_COLOUR:
    .word 0x01EDFA
# default location of the S tetromino as x, y values in an array
S_TETROMINO:
    .word 8, 1, 9, 1, 7, 2, 8, 2, 8, 2
# colour of the S tetromino
S_COLOUR:
    .word 0xEA141C
# default location of the Z tetromino as x, y values in an array
Z_TETROMINO:
    .word 7, 1, 8, 1, 8, 2, 9, 2, 8, 2
# colour of the Z tetromino
Z_COLOUR:
    .word 0x53DA3F
# default location of the L tetromino as x, y values in an array
L_TETROMINO:
    .word 7, 1, 7, 2, 7, 3, 8, 3, 7, 2
# colour of the L tetromino
L_COLOUR:
    .word 0xFF910C
# default location of the J tetromino as x, y values in an array
J_TETROMINO:
    .word 8, 1, 8, 2, 8, 3, 7, 3, 8, 2
# colour of the J tetromino
J_COLOUR:
    .word 0xFFC0CB
# default location of the T tetromino as x, y values in an array
T_TETROMINO:
    .word 6, 1, 7, 1, 8, 1, 7, 2, 7, 1
# colour of the T tetromino
T_COLOUR:
    .word 0x78256F
# default location of the O tetromino as x, y values in an array
O_TETROMINO:
    .word 7, 1, 7, 2, 8, 1, 8, 2, 0, 0
# colour of the O tetromino
O_COLOUR:
    .word 0xFEFB34
##############################################################################
# Mutable Data
##############################################################################
# Memomory allocated for the current selected tetromino  
CURR_TETROMINO:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
# Memory allocated for the colour of the current tetromino
CURR_COLOUR:
    .word 0x0

# Memory allocated for the future tetromino location
FUT_TETROMINO:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    
# Memory allocated for the collision state, stores a value of 0 if no collision, 1 if its a wall collision, 2 if its a bottom collision
COLLISION_STATE:  
    .word 0

# Memory allocated to store the colour information of previously places blocks : TETRIS_WIDTH * TETRIS_HEIGHT * 4 = 16 * 24 * 4 = 1536 bytes
PREVIOUS_BLOCKS:
    .space 1536
    
# Memory allocated to store if the O tetromino is selected
O_SELECTED:
    .word 0
    
# Memory allocated to store if the future move is the result of a down movement
DOWN_MOVEMENT:
    .word 0
    
# Memory allocated for the counter to set the future tetromino position due to gravity
GRAV_COUNT:
    .word 1
# Memory allocated to store the score
SCORE:
    .word 0
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:
    # Initialize the game
    jal draw_border_with_checkered_pattern
    
    jal set_random_tetromino
    
    jal draw_tetromino          # draw the tetromino
    
game_loop:
	# 1a. Check if key has been pressed
	lw $t0, ADDR_KBRD           # $t0 = base address for keyboard
    lw $t8, 0($t0)              # Load first word from keyboard
    bne $t8, 1, keyboard_input_end  # check if a key is pressed
	
    # 1b. Check which key has been pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, exit             # Check if the q key was pressed
    beq $a0, 0x64, handle_d_press   # Check if the d key was pressed
    beq $a0, 0x61, handle_a_press   # Check if the a key was pressed
    beq $a0, 0x73, handle_s_press   # Check if the s key was pressed
    beq $a0, 0x77, handle_w_press   # Check if the w key was pressed
    keyboard_input_end:
    # 2a. Check for collisions
    jal check_collision
	# 2b. Update locations
	jal update_location
	
	jal gravity_effect
	
	# 3. Draw the screen
    
    jal draw_border_with_checkered_pattern
    jal draw_previously_placed_blocks
    jal draw_tetromino          # draw the tetromino
    
	# 4. Sleep
	li $a0, 16
	jal sleep
    
    
    #5. Go back to 1
    b game_loop

# - $a0: number of milliseconds for the program to sleep for
sleep:
    li $v0, 32
    syscall
    jr $ra

exit:
    li $v0, 10
    syscall

# gravity effect
gravity_effect:
    addi $sp, $sp, -4       # Allocate space for the return address
    sw $ra, 0($sp)          # Store the return address
    
    lw $t0, GRAV_COUNT     # load the gravity counter
	la $t1, GRAV_COUNT     # load the address of the gravity counter
	li $t2, 30             # gravity speed
	div $t0, $t2           # divide by 60
	mfhi $t3               # get the remainder
	bne $t3, 0, no_gravity_effect
	jal move_future_location_down
	jal check_collision    # check for collision
	la $t1, GRAV_COUNT     # load the address of the gravity counter
	sw $zero, ($t1)
	li $t0, 0              # set the counter to zero
	no_gravity_effect:
	   addi $t0, $t0, 1    # increment the gravity counter by 1
	   sw $t0, ($t1)       # save the gravity counter
	   
	lw $ra, 0($sp)          # Restore the return address
    addi $sp, $sp, 4        # Deallocate space for the return address
    jr $ra                  # return calling function
    
# draws the previously placed blocks
# - $t0: stores the address to write to on the bitmap display
# - $t1: stores the address to read from the previous blocks array
# - $t2: stores the x value of the current pixel to draw
# - $t3: stores the y value of the current pixel to draw
# - $t4: stores the width of the tetris playing area
# - $t5: stores the height of the tetris playing area
# - $t6: stores the x offset in bytes
# - $t7: stores the y offset in bytes
# - $t8: stores the colour of the pixel of the previously placed blocks
draw_previously_placed_blocks:
    addi $sp, $sp, -4       # Allocate space for the return address
    sw $ra, 0($sp)          # Store the return address
    lw $t4, TETRIS_WIDTH    # Store the width
    lw $t5, TETRIS_HEIGHT   # Store the height
    li $t3, 0               # initialize the y value to 0
    draw_prev_y_loop:
        li $t2, 0                   # initialize the x value to 0
        draw_prev_x_loop:
            la $t1, PREVIOUS_BLOCKS # load the address of the array that stores the previously placed blocks
            sll $t6, $t2, 2         # store the x offset
            sll $t7, $t3, 6         # store the y offset
            add $t1, $t1, $t6       # add the x offset
            add $t1, $t1, $t7       # add the y offset
            
            lw $t8, ($t1)           # load the colour of pixel at location (x,y) from the previously placed blocks
            bne $t8, 0, draw_the_current_pixel 
            after_pixel_is_drawn:
            addi $t2, $t2, 1        # increment the x value by 1
            blt $t2, $t4, draw_prev_x_loop
        addi $t3, $t3, 1        # increment the y value by 1
        blt $t3, $t5, draw_prev_y_loop
    b draw_prev_return  # return
    
    draw_the_current_pixel:
        addi $sp, $sp, -4   # Allocate space for $t0
        sw $t0, ($sp)       # Store $t0
        addi $sp, $sp, -4   # Allocate space for $t1
        sw $t1, ($sp)       # Store $t1
        addi $sp, $sp, -4   # Allocate space for $t2
        sw $t2, ($sp)       # Store $t2
        
        add $a0, $zero, $t2 # Store the x value on $a0
        add $a1, $zero, $t3 # Store the y value on $a1
        add $a2, $zero, $t8 # Store the colour of the pixel to draw in $a3
        jal draw_pixel
        
        lw $t2, ($sp)       # Restore $t2
        addi $sp, $sp, 4    # Deallocate space for $t2
        lw $t1, ($sp)       # Restore $t1
        addi $sp, $sp, 4    # Deallocate space for $t1
        lw $t0, ($sp)       # Restore $t0
        addi $sp, $sp, 4    # Deallocate space for $t0
        b after_pixel_is_drawn
    
    draw_prev_return:
        lw $ra, 0($sp)          # Restore the return address
        addi $sp, $sp, 4        # Deallocate space for the return address
        jr $ra                  # return calling function
          
# set a random tetromino to the current tetromino location, the future tetromino location and the colour
# - $a0: stores the randomly generated number between 0 and 6 inclusive, and then it stores the address of the default location of the selected tetromino
# - $t0: stores the address of the O_SELECTED variable
# - $t1: stores the value to be set into O_SELECTED
# - $t2: stores the colour of the selected tetromino
set_random_tetromino:
    addi $sp, $sp, -4       # Allocate space for the return address
    sw $ra, 0($sp)          # Store the return address
    
    li $v0 , 42     # generate a random number to be stored in $a0
    li $a0 , 0
    li $a1 , 7  
    syscall
    beq $a0, 0, O_chosen    # check which tetromino was chosen
    beq $a0, 1, I_chosen
    beq $a0, 2, S_chosen
    beq $a0, 3, Z_chosen
    beq $a0, 4, L_chosen
    beq $a0, 5, J_chosen
    beq $a0, 6, T_chosen
    
    O_chosen:
        la $a0, O_TETROMINO 
        lw $t2, O_COLOUR
        la $t0, O_SELECTED
        li $t1, 1
        sw $t1, ($t0)   # set the O selected to 1
        b after_tetromino_is_chosen
    I_chosen:
        la $a0, I_TETROMINO 
        lw $t2, I_COLOUR
        la $t0, O_SELECTED
        sw $zero, ($t0)   # set the O selected to 0
        b after_tetromino_is_chosen
    S_chosen:
        la $a0, S_TETROMINO 
        lw $t2, S_COLOUR    
        la $t0, O_SELECTED
        sw $zero, ($t0)   # set the O selected to 0
        b after_tetromino_is_chosen
    Z_chosen:
        la $a0, Z_TETROMINO 
        lw $t2, Z_COLOUR    
        la $t0, O_SELECTED
        sw $zero, ($t0)   # set the O selected to 0
        b after_tetromino_is_chosen
    L_chosen:
        la $a0, L_TETROMINO 
        lw $t2, L_COLOUR    
        la $t0, O_SELECTED
        sw $zero, ($t0)   # set the O selected to 0
        b after_tetromino_is_chosen
    J_chosen:
        la $a0, J_TETROMINO 
        lw $t2, J_COLOUR    
        la $t0, O_SELECTED
        sw $zero, ($t0)   # set the O selected to 0
        b after_tetromino_is_chosen
    T_chosen:
        la $a0, T_TETROMINO 
        lw $t2, T_COLOUR    
        la $t0, O_SELECTED
        sw $zero, ($t0)   # set the O selected to 0
        b after_tetromino_is_chosen
    after_tetromino_is_chosen:
        la $a1, CURR_TETROMINO
        jal copy_tetromino  # copy the selected tetromino in the current tetromino
        la $a0, CURR_TETROMINO
        la $a1, FUT_TETROMINO
        jal copy_tetromino  # copy the selected tetromino in the future tetromino
        la $t1, CURR_COLOUR # load the address of the current colour
        sw $t2, ($t1)       # store the colour
        
        lw $ra, 0($sp)          # Restore the return address
        addi $sp, $sp, 4        # Deallocate space for the return address
        jr $ra                  # return calling function
    
# handles the case when the key d is pressed by setting the future location of the tetromino
# - $t0: stores the address of the current tetromino
# - $t1: stores the address of the future tetromino
# - $t2: loop counter
# - $t3: stores the x or y value for a pixel of the tetromino in the loop iteration
# - $t4: stores the address of DOWN_MOVEMENT
handle_d_press:
    la $t4, DOWN_MOVEMENT   # load the address of the downmovement
    sw $zero, ($t4)         # set down movement to zero
    la $t0, CURR_TETROMINO
    la $t1, FUT_TETROMINO
    addi $t2, $zero, 0      # set the loop counter to 0
    
    handle_D_press_loop_start:
        lw $t3, ($t0)       # load the x value
        addi $t3, $t3, 1    # increment the x value by 1
        sw $t3, ($t1)       # store the new value in the future tetromino
        lw $t3, 4($t0)      # load the  y value
        sw $t3, 4($t1)      # store the previous y value in the future tetromino
        addi $t0, $t0, 8    # increment the pointer to the current tetromino array by 8 bytes
        addi $t1, $t1, 8    # increment the pointer to the future tetromino array by 8 bytes
        addi $t2, $t2, 1    # increment the loop counter by 1
        blt $t2, 5, handle_D_press_loop_start   # check the loop condition
    b keyboard_input_end
    
# handles the case when the key a is pressed by setting the future location of the tetromino
# - $t0: stores the address of the current tetromino
# - $t1: stores the address of the future tetromino
# - $t2: loop counter
# - $t3: stores the x or y value for a pixel of the tetromino in the loop iteration
# - $t4: stores the address of DOWN_MOVEMENT
handle_a_press:
    la $t4, DOWN_MOVEMENT   # load the address of the downmovement
    sw $zero, ($t4)         # set down movement to zero
    la $t0, CURR_TETROMINO
    la $t1, FUT_TETROMINO
    addi $t2, $zero, 0      # set the loop counter to 0
    
    handle_a_press_loop_start:
        lw $t3, ($t0)       # load the x value
        addi $t3, $t3, -1   # increment the x value by -1
        sw $t3, ($t1)       # store the new value in the future tetromino
        lw $t3, 4($t0)      # load the  y value
        sw $t3, 4($t1)      # store the previous y value in the future tetromino
        addi $t0, $t0, 8    # increment the pointer to the current tetromino array by 8 bytes
        addi $t1, $t1, 8    # increment the pointer to the future tetromino array by 8 bytes
        addi $t2, $t2, 1    # increment the loop counter by 1
        blt $t2, 5, handle_a_press_loop_start   # check the loop condition
    b keyboard_input_end

# handles the case when the key s is pressed by setting the future location of the tetromino
# - $t0: stores the address of the current tetromino
# - $t1: stores the address of the future tetromino
# - $t2: loop counter
# - $t3: stores the x or y value for a pixel of the tetromino in the loop iteration
# - $t4: stores the address of DOWN_MOVEMENT
# - $t5: stores a temporary value to be loaded into DOWN_MOVEMENT
handle_s_press:
    la $t4, DOWN_MOVEMENT   # load the address of the downmovement
    li $t5, 1               # load 1 into $t5
    sw $t5, ($t4)           # set down movement to 1
    
    la $t0, CURR_TETROMINO
    la $t1, FUT_TETROMINO
    addi $t2, $zero, 0      # set the loop counter to 0
    
    handle_s_press_loop_start:
        lw $t3, ($t0)       # load the x value
        sw $t3, ($t1)       # store the current x value in the future tetromino
        lw $t3, 4($t0)      # load the y value
        addi $t3, $t3, 1    # increment the y value by 1
        sw $t3, 4($t1)      # store the previous y value in the future tetromino
        addi $t0, $t0, 8    # increment the pointer to the current tetromino array by 8 bytes
        addi $t1, $t1, 8    # increment the pointer to the future tetromino array by 8 bytes
        addi $t2, $t2, 1    # increment the loop counter by 1
        blt $t2, 5, handle_s_press_loop_start   # check the loop condition
    
    b keyboard_input_end

# moves the future location of the tetromino down by 1 unit
# - $t1: stores the address of the future tetromino
# - $t2: loop counter
# - $t3: stores the x or y value for a pixel of the tetromino in the loop iteration
# - $t4: stores the address of DOWN_MOVEMENT
# - $t5: stores a temporary value to be loaded into DOWN_MOVEMENT
move_future_location_down:
    la $t4, DOWN_MOVEMENT   # load the address of the downmovement
    li $t5, 1               # load 1 into $t5
    sw $t5, ($t4)           # set down movement to 1
    
    la $t1, FUT_TETROMINO
    addi $t2, $zero, 0      # set the loop counter to 0
    move_down_loop_start:
        lw $t3, 4($t1)      # load the y value
        addi $t3, $t3, 1    # increment the y value by 1
        sw $t3, 4($t1)      # store the new y value in the future tetromino
        addi $t1, $t1, 8    # increment the pointer to the future tetromino array by 8 bytes
        addi $t2, $t2, 1    # increment the loop counter by 1
        blt $t2, 5, move_down_loop_start   # check the loop condition
    jr $ra

# handles the case when the key w is pressed by setting the future location of the tetromino
# - $t0: stores the address of the current tetromino
# - $t1: stores the address of the future tetromino
# - $t2: loop counter
# - $t3: stores the previous x value for a pixel of the tetromino in the loop iteration
# - $t4: stores the previous y value for a pixel of the tetromino in the loop iteration
# - $t5: stores the future x value for a pixel of the tetromino in the loop iteration
# - $t6: stores the future y value for a pixel of the tetromino in the loop iteration
# - $t7: stores the pivot x value for a pixel of the tetromino in the loop iteration
# - $t8: stores the pivot y value for a pixel of the tetromino in the loop iteration
# - $t9: stores the address of DOWN_MOVEMENT
handle_w_press:
    la $t9, DOWN_MOVEMENT   # load the address of the downmovement
    sw $zero, ($t9)         # set down movement to zero
    
    lw $t0, O_SELECTED      # check if O tetromino is the current tetromino
    beq $t0, 1, keyboard_input_end  # if O tetromino is selected we dont need to rotate as it is symmetrical along all axes
    la $t0, CURR_TETROMINO
    la $t1, FUT_TETROMINO
    addi $t2, $zero, 0      # set the loop counter to 0
    
    lw $t7, 32($t0)         # load the pivot value for x
    lw $t8, 36($t0)         # load the pivot value for y
    
    handle_w_press_loop_start:
        lw $t3, ($t0)       # load the current x value
        lw $t4, 4($t0)      # load the current y value
        
        add $t5, $t8, $t7   # future x = y pivot + x pivot
        sub $t5, $t5, $t4   # future x -= current y
        sw $t5, ($t1)       # store the future x value
        
        sub $t6, $t8, $t7   # future y = y pivot - x pivot
        add $t6, $t6, $t3   # future y += current x
        sw $t6, 4($t1)      # store the future y value
        
        addi $t0, $t0, 8    # increment the pointer to the current tetromino array by 8 bytes
        addi $t1, $t1, 8    # increment the pointer to the future tetromino array by 8 bytes
        addi $t2, $t2, 1    # increment the loop counter by 1
        blt $t2, 5, handle_w_press_loop_start   # check the loop condition
    
    b keyboard_input_end


# Checks if the future tetromino location collides with something in the board and sets the COLLISION_STATE variable
# - $t0: the loop counter
# - $t1: the address of the collision state
# - $t2: the address of the future tetromino
# - $t3: stores the x value for the future pixel
# - $t4: stores the y value for the future pixel
# - $t5: stores the width - 1 of the tetris playing area
# - $t6: stores the height -1 of the tetris playing area 
# - $t7: stores the new value of the collision state to be loaded in the actual collision state variable
# - $t8: stores the address of the array of the previously placed blocks which is then modified 
# - $t9: stores the colour of a previously placed block
check_collision:
    addi $t0, $zero, 0      # set the loop counter
    la $t1, COLLISION_STATE # load the address of the collision state
    la $t2, FUT_TETROMINO   # load the address of the future tetromino position
    sw $zero, ($t1)         # set the default value of the collision state to 0
    lw $t5, TETRIS_WIDTH    # load the width of the tetris playing area
    lw $t6, TETRIS_HEIGHT   # load the height of the tetris playing area
    addi $t5, $t5 -1        # decrement the width by one
    addi $t6, $t6,-1        # decrement the height by one  
    check_collision_loop_start:
        la $t8, PREVIOUS_BLOCKS # load the address of the previously placed blocks
        lw $t3, ($t2)       # load the x value of the future pixel
        lw $t4, 4($t2)      # load the y value of the future pixel
        
        beq $t3, $zero, wall_collision          # if the pixel collides with the left border
        beq $t3, $t5, wall_collision            # if the pixel collides with the right border
        beq $t4, $zero, wall_collision          # if the pixel collides with the top border
        beq $t4, $t6, bottom_block_collision    # if the pixel collides with the bottom border
        
        sll $t3, $t3, 2                         # store the x offset in number of bytes
        sll $t4, $t4, 6                         # store the y offset in number of bytes
        add $t8, $t8, $t3                       # add the x offset to the pointer to the previously placed blocks array
        add $t8, $t8, $t4                       # add the y offset to the pointer to the previously placed blocks array
        lw $t9, ($t8)                           # get the colour stored at that location
        lw $t8, DOWN_MOVEMENT                   # load the value of down movement 
        bne $t9, $0, check_down_movement      # if the colour is not 0, i.e. there is a block at that location
        
        addi $t2, $t2, 8    # increment the pointer to the address of the future tetromino by 8
        addi $t0, $t0, 1    # increment the loop counter by 1
        blt $t0, 4, check_collision_loop_start  # check the loop condition
        b check_collision_return    # if no collision we just return
    
    check_down_movement:
        beq $t8, 1, bottom_block_collision  # check if the future movement was a result of a down movement
        b wall_collision
        
    wall_collision:
        addi $t7, $zero, 1          
        sw $t7, ($t1)               # set the collision state to 1
        b check_collision_return    # return
    bottom_block_collision:
        addi $t7, $zero, 2          
        sw $t7, ($t1)               # set the collision state to 2
        b check_collision_return    # return
    check_collision_return:
        jr $ra      # return to the calling function
    
# Updates the location of the current tetromino, by checking the checking the collision state, if it collides then it will not update 
# - $t0 - stores the value of the collision state
update_location:
    addi $sp, $sp, -4       # Allocate space for the return address
    sw $ra, 0($sp)          # Store the return address
    lw $t0, COLLISION_STATE     # load the collision state into $t0
    
    beq $t0, 0, collision_state_0       # if the collision state is 0, there is no collision and we can safely update the current tetromino location to its future location
    beq $t0, 1, collision_state_1       # if the collision state is 1, we wont update the current location of the tetromino
    beq $t0, 2, collision_state_2       # if the collision state is 2, we store the tetromino in the previously placed blocks and load in a new tetromino
    
    collision_state_0:
        la $a0, FUT_TETROMINO       # loads the address of the future tetromino 
        la $a1, CURR_TETROMINO      # loads the address of the current tetromino
        jal copy_tetromino          # copy the future tetromino location into the current tetromino location
        b update_location_return    # return
    
    collision_state_1:                  
        la $a0, CURR_TETROMINO      # loads the address of the current tetromino 
        la $a1, FUT_TETROMINO       # loads the address of the future tetromino
        jal copy_tetromino          # copy the current tetromino location into the future tetromino location
        b update_location_return    # return
    
    collision_state_2:
        jal store_to_previously_placed_blocks
        jal clear_lines
        jal set_random_tetromino
        jal check_collision
        lw $t0, COLLISION_STATE # check the collision state of the new tetromino
        bne $t0, 0, exit
    
    update_location_return:
        lw $ra, 0($sp)          # Restore the return address
        addi $sp, $sp, 4        # Deallocate space for the return address
        jr $ra                  # return calling function

# removes any filled lines on the previously placed blocks and shifts the blocks above the removed lines down by the number of removed lines
# - $t0: the y offset loop counter
# - $t1: the x offset loop counter
# - $t2: the address of a pixel on the previously allocated blocks array
# - $t3: the end of the y offset for the y loop
# - $t4: the end of the x offset for the the x loop
# - $t5: the colour of a particular pixel
# - $t6: the offset first row from the top that is full which will be cleared
# - $t7: number of rows that were cleared
clear_lines:
    addi $sp, $sp, -4       # Allocate space for the return address
    sw $ra, 0($sp)          # Store the return address
    
    li $t6, 0               # set $t6 and $t7 to 0 initally. If these values are unchanged, then no rows were cleared
    li $t7, 0
    
    lw $t3, TETRIS_HEIGHT   # load the height
    addi $t3, $t3, -1       # decrement the height by 1
    sll $t3, $t3, 6         # multiply by 2^6
    
    lw $t4, TETRIS_WIDTH    # load the width
    addi $t4, $t4, -1       # decrement the width by 1
    sll $t4, $t4, 2         # multiply by 2^2
    
    li $t0, 1               # set the y loop counter to 1 
    sll $t0, $t0, 6         # multiply by 2^6 to get the number of bytes in the y offset
    clear_lines_y_loop:
        li $t1, 1               # set the x loop counter to 1
        sll $t1, $t1, 2         # multiply 2^2 to get the number of bytes in the x offset
        clear_lines_x_loop:
        la $t2, PREVIOUS_BLOCKS                         # load the address of the previous blocks array
            add $t2, $t2, $t0                           # add the y offset
            add $t2, $t2, $t1                           # add the x offset
            
            lw $t5, ($t2)                               # get the colour of the pixel into $t5
            beq $t5, $zero, after_clear_lines_x_loop    # if the colour of a pixel is zero, it means this particular row is not filled so we jump to the next row
            
            addi $t1 , $t1, 4                           # increment the x offset by 4
            blt $t1, $t4, clear_lines_x_loop
            
        handle_row_is_full:
            add $a0, $zero, $t0     # set the y offset to $a0
            la $a1, PREVIOUS_BLOCKS # set the address of the previous blocks array to $a0
            jal shift_down
            la $t8, SCORE           # load the addres of the score
            lw $t9, SCORE           # load the score
            addi $t9, $t9, 1        # increment the score by 1
            sw $t9, ($t8)           # save the score
            
        after_clear_lines_x_loop:
            addi $t0, $t0, 64   # increment the y offset by 64
            blt $t0, $t3, clear_lines_y_loop
        
    clear_lines_return:
        lw $ra, 0($sp)          # Restore the return address
        addi $sp, $sp, 4        # Deallocate space for the return address
        jr $ra                  # return calling function



# shifts the entire previous blocks array by one row down until $a0
# - $a0: the y offset of the row to start shifting from
# - $a1: the address of the previous blocks array
shift_down:
    add $a0, $a1, $a0   # add the y offset
    addi $a0, $a0, -4   # get to the last pixel of the previous row
    shift_down_loop_start:
        lw $a2, ($a0)       # load the colour of the pixel into $t0
        sw $a2, 64($a0)     # store the colour in the pixel below it
        addi $a0, $a0, -4   # decrement the pointer by 4 to get to the previous pixel
        bne $a0, $a1, shift_down_loop_start
    jr $ra  # return to the calling function
    

# stores the current tetromino into the previously placed blocks array. It stores the colour in the array
# - $t0: the loop counter
# - $t1: the address of the previously placed blocks array
# - $t2: the address of the current tetromino
# - $t3: the colour of the current tetromino
# - $t4: the x offset in bytes
# - $t5: the y offset in bytes
store_to_previously_placed_blocks:
    addi $t0, $zero, 0      # set the loop counter
    la $t2, CURR_TETROMINO  # load the address of the current tetromino
    lw $t3, CURR_COLOUR     # load the colour of the current tetromino
    store_to_previously_placed_blocks_loop_start:
        la $t1, PREVIOUS_BLOCKS     # load the address of the previously placed blocks array
        lw $t4, ($t2)               # load the x value
        lw $t5, 4($t2)              # load the y value
        sll $t4, $t4, 2             # store the x offset in bytes
        sll $t5, $t5, 6             # store the y offset in bytes
        add $t1, $t1, $t4           # add the x offset
        add $t1, $t1, $t5           # add the y offset
        sw $t3, ($t1)               # store the colour in that location
        addi $t2, $t2, 8            # increment the pointer to the current tetromino by 8
        addi $t0, $t0, 1            # increment the loop counter
        blt $t0, 4, store_to_previously_placed_blocks_loop_start    # check the loop condition
    jr $ra  #return to the calling function

# The code for drawing a border with checkered pattern
# - $a0: the width of the border in pixels
# - $a1: the height of the border in pixels
# - $t0: the address of the first pixel (top left) in the bitmap
# - $t1: the horizontal offset of the first pixel in the line.
# - $t2: the vertical offset of the first pixel in the line.
# - #t3: the location in bitmap memory of the current pixel to draw 
# - $t4: the bitmap location for the end of a row for the inner loop
# - $t5: the bitmap location for the end of the horizontal line for the outer loop
# - $t6: the colour to draw
# - $t7: stores $t4 - 4
# - $t8: stores $t5 - 128
# - $t9: stores a 1 or 0 if we have to draw light gray or dark gray
draw_border_with_checkered_pattern:
    lw $t0, TETRIS_START
    Lw $t1, TETRIS_WIDTH    
    add $a0, $zero, $t1     # set width of border to tetris width
    Lw $t1, TETRIS_HEIGHT 
    add $a1, $zero, $t1     # set height of border to tetris height
    add $t2, $zero, $zero   # set the vertical offset to zero
    sll $t5, $a1, 7         # set the height of rectangle from pixels to rows of bytes (by multiplying $a1 by 128) 
    addi $t8, $t5, -128     # stores $t5 - 128
    sll $t4, $a0, 2         # set width of line from pixels to bytes (by multiplying $a0 by 4)
    addi $t7, $t4, -4       # stores $t4 - 4
    add $t9, $zero, $zero   # sets $t9 to an initial value of 0
    
outer_top:
    add $t1, $zero, $zero   # set the horizontal offset to zero
    
    inner_top:
        add $t3, $t1, $t2           # store the total offset of the starting pixel (relative to $t0)
        add $t3, $t0, $t3           # calculate the location of the starting pixel ($t0 + offset)
        
        # Check if we are drawing the border or the inner checkered pattern
        beq $t2, $zero, draw_border_pixel   # If vertical offset is zero, draw border pixel
        beq $t1, $zero, draw_border_pixel   # If horizontal offset is zero, draw border pixel
        beq $t2, $t8, draw_border_pixel     # If vertical offset is at the end, draw border pixel
        beq $t1, $t7, draw_border_pixel     # If horizontal offset is at the end, draw border pixel
    
    draw_inside_pixel:
        li $t6, 0xF7F4F4            # $t6 = very light gray so that when multiplied with not of zero gives a dark gray
        multu $t6, $t9              # choose the alternate colour
        mflo $t6                    # load the alternate colout into $t6
        nor $t9, $t9, $t9           # store the not value of $t9 into itself
        sw $t6, 0($t3)              # paint the current location white
        addi $t1, $t1, 4            # move horizontal offset to the right by one pixel
        beq $t1, $t4, inner_end     # break out of the line-drawing loop
        j inner_top                 # jump to the start of the inner loop
    
    draw_border_pixel:
        li $t6, 0xFFFFFF            # $t6 = white
        sw $t6, 0($t3)              # paint the current location white
        addi $t1, $t1, 4            # move horizontal offset to the right by one pixel
        beq $t1, $t4, inner_end     # break out of the line-drawing loop
        j inner_top                 # jump to the start of the inner loop
        
    inner_end:
        addi $t2, $t2, 128          # move vertical offset down by one line
        beq $t2, $t5, outer_end     # on last line, break out of the outer loop
        nor $t9, $t9, $t9           # store the not value of $t9 into itself
        j outer_top                 # jump to the top of the outer loop
outer_end:
    jr $ra                          # return to calling program

# copies the tetromino from $a0 into $a1
# - $a0: The memory address of the selected tetromino
# - $a1: The memory address to copy into
# - $t0: The loop counter
# - $t1: The value of a particular index of the default tetromino array
copy_tetromino:
    li $t0, 0       # set the loop counter to 0
copy_tetromino_loop_start:
        lw $t1, ($a0)               # set $t1 to the current address of $a0
        sw $t1, ($a1)               # set the current value of tetromino into the array of the current tetromino
        addi $a0, $a0, 4            # increment the address by 4 to get to the next index
        addi $a1, $a1, 4            # same as above
        addi $t0, $t0, 1            # increment the loop counter by 1
        blt $t0, 10, copy_tetromino_loop_start  # check if the loop counter is less than 8 and loop again
    jr $ra  # return to calling 
    
# draws the current tetromino
# - $a0: the memory address of the current tetromino
# - $a1: the colour of the current tetromino
draw_tetromino:
    la $a0, CURR_TETROMINO      # load the address of the current tetromino 
    lw $a1, CURR_COLOUR         # load the value of the current colour
    addi $sp, $sp, -4       # Allocate space for the return address
    sw $ra, 0($sp)          # Store the return address
    
    add $s0, $zero, $a0     # Store the value of $a0 in $s0
    
    add $a2, $zero, $a1     # Store the colour in $a2
    lw $a0, 0($s0)          # load the x value of the current pixel into $a0
    lw $a1, 4($s0)          # load the y value of the current pixel into $a1
    jal draw_pixel          # draw the pixel
    
    lw $a0, 8($s0)          # load the x value of the current pixel into $a0
    lw $a1, 12($s0)          # load the y value of the current pixel into $a1
    jal draw_pixel          # draw the pixel
    
    lw $a0, 16($s0)          # load the x value of the current pixel into $a0
    lw $a1, 20($s0)          # load the y value of the current pixel into $a1
    jal draw_pixel          # draw the pixel
    
    lw $a0, 24($s0)          # load the x value of the current pixel into $a0
    lw $a1, 28($s0)          # load the y value of the current pixel into $a1
    jal draw_pixel          # draw the pixel
    
    lw $ra, 0($sp)          # Restore the return address
    addi $sp, $sp, 4        # Deallocate space for the return address
    jr $ra  # return to calling

# draws the pixel at x and y coordinates given by $a0 and $a1
# - $a0: the x coordinate of the pixel
# - $a1: the y coordinate of the pixel
# - $a2: The colour of the pixel
draw_pixel:
    lw $t0, ADDR_DSPL       # stores the starting address of the display
    sll $t1, $a0, 2         # multiply the x value by  2^2 to get the width in bytes
    add $t0, $t0, $t1       # add the x offset
    sll $t2, $a1, 7         # multiply the y value by 2^7 to get the height in bytes
    add $t0, $t0, $t2       # add the y offset
    sw $a2, ($t0)           # draw the pixel
    jr $ra
    
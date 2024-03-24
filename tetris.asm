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
# The actual width of the screen
DISP_WIDTH:
    .word 32
# default location of the I tetromino as x, y values in an array
I_TETROMINO:
    .word 8, 1,8, 2, 8, 3, 8, 4
# colour of the I tetroomino
I_COLOUR:
    .word 0x01EDFA
##############################################################################
# Mutable Data
##############################################################################
# Memomory allocated for the current selected tetromino  
CURR_TETROMINO:
    .word 0, 0, 0, 0, 0, 0, 0, 0
# Memory allocated for the colour of the current tetromino
CURR_COLOUR:
    .word 0x0
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:
    # Initialize the game
    jal draw_border_with_checkered_pattern
    
game_loop:
	# 1a. Check if key has been pressed
	lw $t0, ADDR_KBRD           # $t0 = base address for keyboard
    lw $t8, 0($t0)              # Load first word from keyboard
    bne $t8, 1, keyboard_input_end  # check if a key is pressed
	
    # 1b. Check which key has been pressed
    lw $a0, 4($t0)          # Load second word from keyboard
    beq $a0, 0x71, exit     # Check if the q key was pressed
    
    keyboard_input_end:
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	
	la $a0, I_TETROMINO         # load the address of the I tetromino
    la $a1, CURR_TETROMINO      # load the address of the current tetromino 
    la $a2, I_COLOUR            # load the address of colour of the I tetromino
    la $a3, CURR_COLOUR         # load the address of the colour of the current tetromino
    jal load_curr_tetromino
    
    la $a0, CURR_TETROMINO      # load the address of the current tetromino 
    lw $a1, CURR_COLOUR         # load the value of the current colour
    jal draw_tetromino          # draw the tetromino
    
	# 4. Sleep
	jal sleep

    #5. Go back to 1
    b game_loop


sleep:
    li $v0, 32
    li $a0, 1000
    jr $ra

exit:
    li $v0, 10
    syscall

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

# loads the selected tetromino into the memory of the current tetromino
# - $a0: The memory address of the default location of the selected tetromino
# - $a1: The memory address of the location of the current tetromino
# - $a2: The memory address of the colour of the selected tetromino
# - $a3: The memory address of the colour of the currentt tetromino
# - $t0: The loop counter
# - $t1: The value of a particular index of the default tetromino array
load_curr_tetromino:
    li $t0, 0       # set the loop counter to 0
    load_curr_tetromino_loop_start:
        lw $t1, ($a0)               # set $t1 to the current address of $a0
        sw $t1, ($a1)               # set the current value of tetromino into the array of the current tetromino
        addi $a0, $a0, 4            # increment the address by 4 to get to the next index
        addi $a1, $a1, 4            # same as above
        addi $t0, $t0, 1            # increment the loop counter by 1
        blt $t0, 8, load_curr_tetromino_loop_start  # check if the loop counter is less than 8 and loop again
    lw $t1, ($a2)   # load the colour of the tetromino into $t1
    sw $t1, ($a3)   # set the colour in into thhe current tetromino colour address
    jr $ra  # return to calling 
    
# draws the current tetromino
# - $a0: the memory address of the current tetromino
# - $a1: the colour of the current tetromino
draw_tetromino:
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
    
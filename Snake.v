`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Done at 2023/12/29 
////////////////////////////////////////////////////////
module Snake(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );
	// General VGA control signals
    wire vga_clk;         // 50MHz clock for VGA control
    wire video_on;        // when video_on is 0, the VGA controller is sending
                          // synchronization signals to the display device.
    wire [9:0] xCount; //x pixel
	wire [9:0] yCount; //y pixel  
    wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                          // based for the new coordinate (pixel_x, pixel_y)
      
    wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
    wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
      
    reg  [11:0] rgb_reg;  // RGB value for the current pixel
    reg  [11:0] rgb_next; // RGB value for the next pixel
      
    // Application-specific VGA signals
    reg  [17:0] pixel_addr;
    
    // Instiantiate the VGA sync signal generator
    vga_sync vs0(
      .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
      .visible(video_on), .p_tick(pixel_tick),
      .xCount(xCount), .yCount(yCount)
    );
	
	wire sram_we, sram_en;
	wire [11:0] data_in;
	wire [11:0] data_out;
	wire [16:0] sram_addr;

	assign sram_we =  (usr_led[0]);
	assign sram_en = 1;         
	assign sram_addr = pixel_addr;
	assign data_in = 12'h000;

	wire [11:0] data_out_score;
	wire [16:0] sram_addr_score;
	reg  [17:0] pixel_addr_score;
	assign sram_addr_score = pixel_addr_score;
	wire [11:0] data_out_lose;
	wire [16:0] sram_addr_lose;
	reg  [17:0] pixel_addr_lose;
	assign sram_addr_lose = pixel_addr_lose;
	wire [11:0] data_out_w;
	wire [16:0] sram_addr_e;
	reg  [17:0]pixel_addr_e;
	assign sram_addr_e = pixel_addr_e;
    
	sram_cover #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(320*240))
  	ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
	sram_score #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(10240))
  	ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_score), .data_i(data_in), .data_o(data_out_score));
	sram_lose #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(5120))
  	ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_lose), .data_i(data_in), .data_o(data_out_lose));
    sram_win #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(5120))
    ram4 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_e), .data_i(data_in), .data_o(data_out_w));
    
	clk_divider#(2) clk_divider0(
      .clk(clk),
      .reset(~reset_n),
      .clk_out(vga_clk)
    );
	reg [3:0] P, P_next;
	reg [9:0] appleX;
	reg [8:0] appleY;
	wire [9:0]rand_X;
	wire [8:0]rand_Y;
	wire displayArea; //is it in the active display area?
	
	localparam [3:0] S_init=0, S_move=1,S_end=2, S_stage=3, S_win = 4;
	
	reg [4:0] direction;
	wire lethal, nonLethal;
	reg bad_collision, good_collision, game_over = 0;
	reg apple_inX, apple_inY, apple, border, found; //---------------------------------------------------------------Added border
	integer appleCount, count1, count2, count3;
	reg [6:0] size;
	
	reg [9:0] snakeX[0:127];
	reg [8:0] snakeY[0:127];
	reg [9:0] snakeHeadX;
	reg [9:0] snakeHeadY;
	reg snakeHead;
	reg snakeBody;
	wire update, reset;
	integer maxSize = 16;
    wire btn_level[0:3], btn_pressed[0:3];
    reg  prev_btn_level[0:3];   
    
    debounce btn_db0(
      .clk(clk),
      .btn_input(usr_btn[0]),
      .btn_output(btn_level[0])
    );
    debounce btn_db1(
      .clk(clk),
      .btn_input(usr_btn[1]),
      .btn_output(btn_level[1])
    );
    debounce btn_db2(
      .clk(clk),
      .btn_input(usr_btn[2]),
      .btn_output(btn_level[2])
    );
    debounce btn_db3(
      .clk(clk),
      .btn_input(usr_btn[3]),
      .btn_output(btn_level[3])
    );

	
	
    
	randomGrid rand1(vga_clk, rand_X, rand_Y);
	
	updateClk UPDATE(clk, update);
	
	always @(posedge clk) begin
    if (~reset_n) begin
        prev_btn_level[0] <= 0;
        prev_btn_level[1] <= 0;
        prev_btn_level[2] <= 0;
        prev_btn_level[3] <= 0;
    end
    else begin
        prev_btn_level[0] <= btn_level[0];
        prev_btn_level[1] <= btn_level[1];
        prev_btn_level[2] <= btn_level[2];
        prev_btn_level[3] <= btn_level[3];
    end
end

assign btn_pressed[0] = btn_level[0] & ~prev_btn_level[0];
assign btn_pressed[1] = btn_level[1] & ~prev_btn_level[1];
assign btn_pressed[2] = btn_level[2] & ~prev_btn_level[2];
assign btn_pressed[3] = btn_level[3] & ~prev_btn_level[3];
	
	reg[8:0]counter = 0;
    always @(posedge clk) begin
        if (~reset_n) begin
            P <= S_init;
        end
        else P <= P_next;
    end
    wire win;
    assign win = (counter==12);
    assign win2 = (counter==16);//help me define this
    
    reg [2:0] life;
    always @(*) begin // FSM next-state logic
    case (P)
        S_init: // send an address to the SRAM 
            if(btn_pressed[0]) P_next <= S_move;
            else P_next <= S_init;
        S_move:
            if(life==3) P_next <= S_end;
            else if(game_over) P_next <= S_init;
            else if(win) P_next <= S_stage;
            else P_next <= S_move;
        S_stage:
            if(game_over) P_next <= S_end;
            else if(win2) P_next<=S_win;
            else P_next <= S_stage;
        S_end:
            if(~reset_n) P_next <= S_init;
            else P_next <= S_end;
        S_win:
            if(~reset_n) P_next <= S_init;
            else P_next <= S_win;
        
    endcase
end
    
    always@(posedge vga_clk)begin
        if(game_over)
            life <= life +1;
        else if(P==S_end)
            life <=0;
        else if(P==S_win)
            life <=0;
    end
	//
	always @(posedge vga_clk)//---------------------------------------------------------------Added border function
	begin
		border <= (((xCount >= 0) && (xCount < 11) || (xCount >= 630) && (xCount < 641)) || ((yCount >= 0) && (yCount < 11) || (yCount >= 470) && (yCount < 481)));
	end
	
	always@(posedge vga_clk)
	begin
    if(P==S_move || P == S_stage)begin
        appleCount = appleCount+1;
            if(appleCount == 1)
            begin
                appleX <= 180;
                appleY <= 130;
            end
            else
            begin	
                if(good_collision)
                begin
                    if((rand_X<10) || (rand_X>630) || (rand_Y<10) || (rand_Y>470))
                    begin
                        appleX <= 400;
                        appleY <= 300;
                    end
                    else
                    begin
                        appleX <= rand_X;
                        appleY <= rand_Y;
                    end
                end
                else if(~reset_n)
                begin
                    if((rand_X<10) || (rand_X>630) || (rand_Y<10) || (rand_Y>470))
                    begin
                        appleX <=340;
                        appleY <=430;
                    end
                    else
                    begin
                        appleX <= rand_X;
                        appleY <= rand_Y;
                    end
                end
            end
        end
    end
	always @(posedge vga_clk)
	begin
        if(P==S_move || P == S_stage)begin
		    apple_inX <= (xCount > appleX && xCount < (appleX + 10));
		    apple_inY <= (yCount > appleY && yCount < (appleY + 10));
		    apple = apple_inX && apple_inY;
        end
	end
	//up 1 down 2 left 3 right 4
	always@(posedge clk) begin
	if(~reset_n)direction<=4;
    else if(P==S_init)direction<=4;
	else if(P==S_move || P == S_stage)begin 
	   if(btn_pressed[0]&&direction!=2)direction=1;
	   else if(btn_pressed[1]&&direction!=1)direction=2;
	   else if(btn_pressed[2]&&direction!=4)direction=3;
	   else if(btn_pressed[3]&&direction!=3)direction=4;
	   end
	end
	
	always@(posedge update)
	   
	begin
    if(P==S_init)begin
        snakeX[0]<=50;
        snakeY[0]<=50;
    end else if(reset_n&&P==S_move || P==S_stage)
	begin
		for(count1 = 127; count1 > 0; count1 = count1 - 1)
			begin
				if(count1 <= size - 1)
				begin
					snakeX[count1] = snakeX[count1 - 1];
					snakeY[count1] = snakeY[count1 - 1];
				end
			end
		if(direction==1)snakeY[0] <= (snakeY[0] - 10);
	    else if(direction ==3)snakeX[0] <= (snakeX[0] - 10);
		else if(direction ==2)snakeY[0] <= (snakeY[0] + 10);
		else if(direction ==4)snakeX[0] <= (snakeX[0] + 10);
		end
	else if(~reset_n)
	begin
		for(count3 = 1; count3 < 128; count3 = count3+1)
			begin
			snakeX[count3] = 300;
			snakeY[count3] = 300;
			end
	end
	end
	
		
	always@(posedge vga_clk)
	begin
		found = 0;
		for(count2 = 1; count2 < size; count2 = count2 + 1)
		begin
			if(~found)
			begin				
				snakeBody = ((xCount > snakeX[count2] && xCount < snakeX[count2]+10) && (yCount > snakeY[count2] && yCount < snakeY[count2]+10));
				found = snakeBody;
			end
		end
	end


	
	always@(posedge vga_clk)
	begin	
        if(P==S_move || P == S_stage)begin
		snakeHead = (xCount > snakeX[0] && xCount < (snakeX[0]+10)) && (yCount > snakeY[0] && yCount < (snakeY[0]+10));
        end
    end
	wire bar_region;
	assign lethal = border||snakeBody;
	assign nonLethal = apple;
    assign lethal2 = border||snakeBody||bar_region;
	//good colli
	always @(posedge vga_clk) begin

		if(nonLethal && snakeHead) begin 
	        good_collision=1;
		    size = size+1;
			counter <= counter + 1;
	    end 
		else if(~reset_n)begin 
            size = 1;
			counter <= 0;	
		end
        else if(P==S_init)size = 1;									
		else good_collision=0;
    end
    //bad collison
	always @(posedge vga_clk) begin
        if(~reset_n)
            bad_collision=0;
        else
        if(P==S_init)
            bad_collision = 0;
        else
        if(P==S_move) begin
            if(lethal && snakeHead) 
                bad_collision=1;
		    else bad_collision=0;
        end else if(P==S_stage)begin
            if(lethal2 && snakeHead) 
                bad_collision=1;
		    else bad_collision=0;
        end
        
    end
    //game over
	always @(posedge vga_clk) begin
        if(~reset_n)
            game_over = 0;
        else if(P==S_init)
            game_over = 0;
        else if(P==S_move || P == S_stage)begin
            if(bad_collision) game_over=1;
        end
    end
    //rgb ff						
	always @(posedge vga_clk)begin
	   rgb_reg<=rgb_next;
	end
	wire red;		
	wire green;		
	wire blue;
	wire end_region;
	wire score_region;	
				
	assign red = ((apple || 0));
	assign green = (((snakeHead||snakeBody) && 1));//game over change
	assign blue = ((border && 1) );//---------------------------------------------------------------Added border
	always @(*) begin
        if (~video_on) begin
            rgb_next = 12'h000; // Synchronization period, must set RGB values to zero
        end
        else begin
            if(P==S_init) rgb_next = data_out;
			else if(P == S_move && score_region || P == S_stage && score_region) rgb_next = data_out_score;
			else if(P == S_stage && bar_region) rgb_next = 12'h000; 
			else if(P == S_end && end_region) rgb_next = data_out_lose;
            else if(P == S_win && win_region) rgb_next = data_out_w;
            else if(P == S_end) rgb_next = 12'h515;
            else if(P == S_win) rgb_next = 12'h222;
            else if(green) rgb_next =12'hf00;
            else if(red) rgb_next = 12'h0f0;
            else if (blue) rgb_next = 12'h511;
            else rgb_next = 12'h040;
        end
    end
	assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

	
	assign end_region = yCount >= (88<<1) && yCount < (88+80)<<1 &&
                      (xCount + 127) >= 384 && xCount < 384 + 1;
	assign win_region = yCount >= (88<<1) && yCount < (88+80)<<1 &&
                      (xCount + 127) >= 384 && xCount < 384 + 1;
	assign score_region =  yCount >= (15<<1) && yCount < (15+32)<<1 &&
                      (xCount + 127) >= 476 && xCount < 476 + 1;
	assign bar_region = yCount >= (88<<1) && yCount < (88+80)<<1 &&
                      (xCount + 19) >= 420 && xCount < 420 + 1;
	reg[15:0]score_mem[3:0];

	initial begin
	score_mem[0] = 0; 
	score_mem[1] = 32*64;
	score_mem[2] = 32*64*2;
	score_mem[3] = 32*64*3;
	score_mem[4] = 32*64*4;
	end
	/*
	always@(posedge vga_clk)begin
		if(~reset_n)counter <= 1;
        else if(P==S_init) counter <= 1;
		else if(good_collision)counter <= counter + 1;
		else if(P == S_end) counter <= 1;
	end*/

	always@(posedge vga_clk)begin
		if(~reset_n)begin
			pixel_addr <= 0;
			pixel_addr_lose <= 0;
			pixel_addr_score <= 0;
			pixel_addr_e <= 0;
		end
		else begin
			if(P == S_init)begin
				pixel_addr <= (yCount >> 1) * 320 + (xCount >> 1);
			end
			if(end_region)begin
				pixel_addr_lose<= ((yCount>>1)-88)*64 + 
                      ((xCount +(64*2-1)-384)>>1);
			end
			if(win_region)begin
				pixel_addr_e<= ((yCount>>1)-88)*64 + 
                      ((xCount +(64*2-1)-384)>>1);
			end
			if(score_region)begin
				pixel_addr_score<=(counter%12)*32*64/4+
								((yCount>>1)-15)*64 +
                      			((xCount +(64*2-1)-476)>>1);
			end
		end
	end

	

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////
// need refinement
module appleLocation(vga_clk, xCount, yCount, apple);
	input vga_clk, xCount, yCount;
	wire [9:0] appleX;
	wire [8:0] appleY;
	reg apple_inX, apple_inY;
	output apple;
	wire [9:0]rand_X;
	wire [8:0]rand_Y;
	randomGrid rand1(vga_clk, rand_X, rand_Y);
	
	assign appleX = 0;
	assign appleY = 0;
	
	always @(negedge vga_clk)
	begin
		apple_inX <= (xCount > appleX && xCount < (appleX + 10));
		apple_inY <= (yCount > appleY && yCount < (appleY + 10));
	end
	
	assign apple = apple_inX && apple_inY;
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////
// need refinement
module randomGrid(vga_clk, rand_X, rand_Y);
	input vga_clk;
	output reg [9:0]rand_X;
	output reg [8:0]rand_Y;
	reg [5:0]pointX, pointY = 10;

	always @(posedge vga_clk)
		pointX <= pointX + 3;	
	always @(posedge vga_clk)
		pointY <= pointY + 1;
	always @(posedge vga_clk)
	begin	
		if(pointX>62)
			rand_X <= 620;
		else if (pointX<2)
			rand_X <= 20;
		else
			rand_X <= (pointX * 10);
	end
	
	always @(posedge vga_clk)
	begin	
		if(pointY>46)//---------------------------------------------------------------Changed to 469
			rand_Y <= 460;
		else if (pointY<2)
			rand_Y <= 20;
		else
			rand_Y <= (pointY * 10);
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////
//speed
module updateClk(clk, update);
	input clk;
	output reg update;
	reg [21:0]count;	

	always@(posedge clk)
	begin
		count <= count + 1;
		if(count == 3000000)
		begin
			update <= ~update;
			count <= 0;
		end	
	end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////




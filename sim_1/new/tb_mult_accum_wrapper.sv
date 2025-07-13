`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2025 01:33:56 PM
// Design Name: 
// Module Name: tb_dsp_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "PE_IF.vh"
`include "dsp_sys_arr_pkg.vh"
import dsp_sys_arr_pkg::*;

//`timescale 1ns / 1ns

module tb_mult_accum_wrapper;

    parameter PERIOD = 1.5;
    parameter INPUT_BUFF = 1; 
    parameter FILL_CAP = 32;
    parameter VEC_SIZE = FILL_CAP;   
                              
    parameter IN_STG_1 = 1;
    parameter IN_STG_2 = 1;
    parameter MUL_PIP = 1;
    parameter MUL_OUT_STG = 1;
    parameter ADD_OUT_STG = 1;
    parameter FPOPMODE_STG = 1;
    parameter FPINMODE_STG = 1;
    parameter MODE = 0;
    
    logic CLK = 0, nRST;
    
    // Test Bench Signals
    integer testcase_num;
    string testcase;
    string testphase;
    
    integer total_testcases;
    integer total_failed_testcases;
    
    logic ex_col_in_ready,ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, ex_comp_done;
    error ex_user;
    single_float ex_accum_sum, ex_row_out_dat, ex_col_out_dat;
    
    single_float test;
    shortreal inter;
    shortreal test_row, test_col, test_sum;
    shortreal test_vector [0:VEC_SIZE];
    error test_user;
    int begin_sim;
    
    // clock
    always #(PERIOD/2) CLK++;

    PE_if peif();

    mult_accum_wrapper #(
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
    DUT(CLK, nRST, peif);
     
    task init_tb();
        // Initializing Interface Input Signals
        {peif.col_in_valid, peif.row_in_valid, peif.col_out_ready, peif.row_out_ready, peif.row_in_dat, peif.col_in_dat} = 'B0;  
        nRST = 1'b1;  
        
        // Initializing TB Signals
        {ex_col_in_ready,ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done} = 'B0;
    endtask
    
    task reset_dut();
        @(posedge CLK);
        @(negedge CLK);
        
        nRST = 1'b0;
        
        repeat (2) @(negedge CLK);
        
        nRST = 1'b1;
        
    endtask
    
    task check_outputs(
    input logic check_sum,check_row_dat, check_col_dat,
    input logic col_in_ready, row_in_ready, error_bit, col_out_valid, row_out_valid,
    input single_float accum_sum, row_out_dat, col_out_dat,
    input error user,
    input logic comp_done
  );

    total_testcases += 10;
		
	// Input Neighbor Ports 
    if(peif.col_in_ready != col_in_ready) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Column Input Ready signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, col_in_ready, peif.col_in_ready);
    end

    if(peif.row_in_ready != row_in_ready) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Row Input Ready signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime,testcase, testphase, row_in_ready, peif.row_in_ready);
    end

    // Output Neighbor Ports 
    if((peif.col_out_valid != col_out_valid) && check_col_dat) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Column Output Valid signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime,testcase, testphase, col_out_valid, peif.col_out_valid);
    end

    if((peif.row_out_valid != row_out_valid) && check_row_dat) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Row Output Valid signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime,testcase, testphase, row_out_valid, peif.row_out_valid);
    end
    
    if((peif.col_out_dat != col_out_dat) && check_col_dat) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Column Output Data Bus during %s testcase in the %s test phase. \n Expected %x and got %x\n", $realtime,testcase, testphase, col_out_dat, peif.col_out_dat);
    end

    if((peif.row_out_dat != row_out_dat) && check_row_dat) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Row Output Data Bus during %s testcase in the %s test phase. \n Expected %x and got %x\n", $realtime,testcase, testphase, row_out_dat, peif.row_out_dat);
    end


	// PE outputs
	if((peif.accum_sum != accum_sum) && check_sum) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Accumulated Sum during %s testcase in the %s test phase. \n Expected %x and got %x\n", $realtime,testcase, testphase, accum_sum, peif.accum_sum);
    end
    
    if(peif.error_bit != error_bit) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Error Bit during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime,testcase, testphase, error_bit, peif.error_bit);
    end
    
    if(peif.user != user) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect User message during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime,testcase, testphase, user, peif.user);
    end
    
    if((peif.comp_done != comp_done) && check_sum) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Computation done during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime,testcase, testphase, comp_done, peif.comp_done);
    end

	endtask
    
    function automatic single_float create_single_float(
    input shortreal frac
    );
    
    single_float flt;
    int bits;
   
    bits = $shortrealtobits(frac);
    flt.sign = bits[31];
    flt.exp = bits[30:23];
    flt.mantissa = bits[22:0];
 
    return flt;
    endfunction
    
    
    
    
    
    
    task pass_inputs(
    input succesful_pass,
    input logic row_in_valid, col_in_valid,
    input shortreal row_in_dat, col_in_dat
    );
    
    ex_row_in_ready = 1'b0;
    ex_col_in_ready = 1'b0;
    ex_col_out_valid = 1'b0;
    ex_row_out_valid = 1'b0;
    
    ex_col_out_dat = 'b0;
    ex_row_out_dat = 'b0;
    
    if(~succesful_pass) begin
        check_outputs(1'b0,1'b0,1'b0,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
        ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    end
    
    else begin
        check_outputs(1'b0,row_in_valid,col_in_valid,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
        ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    end
    
    @(negedge CLK);
    peif.row_in_valid = row_in_valid;
    peif.col_in_valid = col_in_valid;
    
    peif.col_in_dat = create_single_float(col_in_dat);
    peif.row_in_dat = create_single_float(row_in_dat);
    
    #(PERIOD*0.1);
    ex_row_in_ready = succesful_pass & row_in_valid;
    ex_col_in_ready = succesful_pass & col_in_valid;
    ex_col_out_valid = 1'b0;
    ex_row_out_valid = 1'b0;
    
    ex_col_out_dat = 'b0;
    ex_row_out_dat = 'b0;
  
    if(~succesful_pass) begin
        check_outputs(1'b0,1'b0,1'b0,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
        ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    end
    
    else begin
        check_outputs(1'b0,row_in_valid,col_in_valid,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
        ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    end
    
    
    @(negedge CLK);
    
    ex_row_in_ready = 1'b0;
    ex_col_in_ready = 1'b0;
   
    ex_col_out_valid = col_in_valid;
    ex_row_out_valid = row_in_valid;
      
    ex_col_out_dat = peif.col_in_dat;
    ex_row_out_dat = peif.row_in_dat;
    
    if(~succesful_pass) begin
        check_outputs(1'b0,1'b0,1'b0,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
        ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    end
    
    else begin
        check_outputs(1'b0,row_in_valid,col_in_valid,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
        ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    end
    
    peif.row_in_valid = 1'B0;
    peif.col_in_valid = 1'B0;
    
    peif.col_in_dat = 'B0;
    peif.row_in_dat = 'B0;
    
    endtask
    
    
    
    
    
    task comp_check(
    input shortreal row, col, sum,
    input error user
    );
    
    wait(peif.comp_done == 1'b1);
    
    inter =  row*col + sum;
    
    ex_row_in_ready = 1'b0;
    ex_col_in_ready = 1'b0;
    ex_col_out_valid = 1'b1; // Not necessarily
    ex_row_out_valid = 1'b1;
    ex_comp_done     = 1'b1;
    
    ex_error_bit = |user;
    ex_user = user;
    
    ex_accum_sum   = $shortrealtobits(inter);
    
    check_outputs(1'b1,1'b0,1'b0,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
    ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    
    @(negedge CLK);
    ex_row_in_ready = 1'b0;
    ex_col_in_ready = 1'b0;
    ex_col_out_valid = 1'b0;
    ex_row_out_valid = 1'b0;
    ex_comp_done     = 1'b0;
    
    ex_error_bit = 1'b0;
    ex_user = 'b0;
    
    ex_accum_sum   = 'b0;
    
    endtask
    
    
    
    
    
    
    task operand_request(
    input logic col_out_ready, row_out_ready,
    input shortreal col_out_dat, row_out_dat
    );
    
    @(negedge CLK);
    ex_col_out_valid = 1'b1;
    ex_row_out_valid = 1'b1;
    ex_col_out_dat = create_single_float(col_out_dat);
    ex_row_out_dat = create_single_float(row_out_dat);
    
    peif.col_out_ready = col_out_ready;
    peif.row_out_ready = row_out_ready;
    
    check_outputs(1'b0,1'b1,1'b1,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
    ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    
    @(negedge CLK);
    ex_col_out_valid = 1'b0;
    ex_row_out_valid = 1'b0;    
    peif.col_out_ready = 'b0;
    peif.row_out_ready = 'b0;
    
    ex_col_out_dat = 'b0;
    ex_row_out_dat = 'b0;
    
    check_outputs(1'b0,1'b1,1'b1,ex_col_in_ready, ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, 
    ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done);
    
    #(PERIOD*0.05);
    endtask
    
//    task pipline_stream(
//        shortreal test_vector [0:VEC_SIZE]
//    );
    
    
//    endtask
    
    
    initial begin
    begin_sim = 0;
    #(100 * 1ns);
    begin_sim = 1;
    end
    
    
    
    
    
    
    initial begin
        testcase_num = 0;
        testcase = "Initialization";
        testphase = "Inititization";
        
        total_testcases = 0;
        total_failed_testcases = 0;
        
        test_row = 0;
        test_col = 0;
        test_sum = 0;
        
        test_user = 'b0;
        
        init_tb();
        reset_dut();
        
        wait(begin_sim);
        
        // DUT ready to process
        // Inputs port valid
        // Output ports ready
        testphase = "Basic Operation";
        
        // First pass inputs to both ports
        testcase = "Passing Operands";
        test_row = 2.0;
        test_col = 2.5;
        pass_inputs(1'b1,1'b1,1'b1,test_row,test_col);
       
        // Verify that computation has been completed succesfully
        testcase = "Checking Computation";
        test_sum = 0;
        comp_check(test_row, test_col, test_sum, test_user);
        
        test_sum += test_col*test_row;
        
        // Dual-Operand request
        @(posedge CLK);              
        testcase = "Operand Request";
        operand_request(1'b1,1'b1,test_col,test_row);
        
        
        // Stream Computation (Check for Accumulated Sum)
        if(ADD_OUT_STG) begin
            testphase = "Stream Computation";
            reset_dut();
            repeat (5) @(posedge CLK);
            
            testcase = "Fill, Compute and Empty";
            
            test_sum = 0;
            
            for(int j=0; j<VEC_SIZE; j++) begin
                test_vector[j] = j+1;
            end
            
            for (int i=0; i < FILL_CAP; i++) begin
                test_row = test_vector[i];
                test_col = test_vector[i];
                pass_inputs(1'b1,1'b1,1'b1,test_row,test_col);
                
                comp_check(test_row, test_col, test_sum, test_user);
            
                test_sum += test_col*test_row;
                
                @(posedge CLK);              
                operand_request(1'b1,1'b1,test_col,test_row);
            end 
            
            testcase = "Fill, and Empty, then compute"; // Fill the port A and B input buffers, by continously reading operands while PE is computing
            reset_dut();
            repeat (5) @(posedge CLK);
            
            test_sum = 0;
            
            for (int i=0; i < FILL_CAP; i++) begin // Through tests we know that buffers can only handle 1 unprocessed operand/s  to be queued
                test_row = test_vector[i];             // Since we are passing both col and row operands at once, they will be buffered and then popped allowing for INPUT_BUFF + 1 operands to be passed in
                test_col = test_vector[i];
                pass_inputs(1'b1,1'b1,1'b1,test_row,test_col);
                             
                operand_request(1'b1,1'b1,test_col,test_row);
            end
            
            
            for (int i=0; i < FILL_CAP; i++) begin
                test_row = test_vector[i];
                test_col = test_vector[i];
                if(i == FILL_CAP) begin
                    comp_check(test_row, test_col, test_sum, test_user);
                end
                test_sum += test_col*test_row;
            end
            
            repeat(2) @(posedge CLK);  
        end
        
        else begin
            testphase = "Stream Computation";
            reset_dut();
            repeat (5) @(posedge CLK);
            
            testcase = "Fill, Compute and Empty";
            
            test_sum = 0;
            
            for(int j=0; j<VEC_SIZE; j++) begin
                test_vector[j] = j+1;
            end
            
            for (int i=0; i < FILL_CAP; i++) begin
                test_row = test_vector[i];
                test_col = test_vector[i];
                pass_inputs(1'b1,1'b1,1'b1,test_row,test_col);
                
                comp_check(test_row, test_col, test_sum, test_user);
            
                test_sum += 0;
                
                @(posedge CLK);              
                operand_request(1'b1,1'b1,test_col,test_row);
            end 
            // Not necessary for pure multiplication computation
//            testcase = "Fill, and Empty, then compute"; // Fill the port A and B input buffers, by continously reading operands while PE is computing
//            reset_dut();
//            repeat (5) @(posedge CLK);
            
//            test_sum = 0;
            
//            for (int i=0; i < FILL_CAP; i++) begin // Through tests we know that buffers can only handle 1 unprocessed operand/s  to be queued
//                test_row = test_vector[i];             // Since we are passing both col and row operands at once, they will be buffered and then popped allowing for INPUT_BUFF + 1 operands to be passed in
//                test_col = test_vector[i];
//                pass_inputs(1'b1,1'b1,1'b1,test_row,test_col);
                             
//                operand_request(1'b1,1'b1,test_col,test_row);
//            end
            
            
//            for (int i=0; i < FILL_CAP; i++) begin
//                test_row = test_vector[i];
//                test_col = test_vector[i];
//                if(i == FILL_CAP-1) begin
//                    comp_check(test_row, test_col, test_sum, test_user);
//                end
//                test_sum += 0;
//            end
            
//            repeat(2) @(posedge CLK);
        end
        // Check that DUT doesnt accept row/column input if row/column operand has not been read
        testphase = "Check Operand Passing";
        reset_dut();
        repeat (5) @(posedge CLK);
        
        // Check only row operand passing 
        testcase = "Row input Passing";
        for (int i=0; i < INPUT_BUFF+1; i++) begin
            if(i == INPUT_BUFF) begin
                test_row = test_vector[i];
                test_col = test_vector[i];
                pass_inputs(1'b0, 1'b1,1'b0,test_row,test_col); 
            end
            
            else begin
                test_row = test_vector[i];          
                test_col = test_vector[i];
                pass_inputs(1'b1, 1'b1,1'b0,test_row,test_col);
            end
        end
        
        // Check only column operand passing
        reset_dut();
        repeat (5) @(posedge CLK);
        testcase = "Column input Passing";
        for (int i=0; i < INPUT_BUFF+1; i++) begin
            if(i == INPUT_BUFF) begin
                test_row = test_vector[i];
                test_col = test_vector[i];
                pass_inputs(1'b0, 1'b0,1'b1,test_row,test_col); 
            end
            
            else begin
                test_row = test_vector[i];          
                test_col = test_vector[i];
                pass_inputs(1'b1, 1'b0,1'b1,test_row,test_col);
            end
        end
        
        // Check for correct compute order
        testphase = "Check Computed Order";
        reset_dut();
        repeat (5) @(posedge CLK);
        
        testcase = "Filling Row Input Buffer";
        for (int i=0; i < INPUT_BUFF; i++) begin // Fill Row Buffer
            test_row = test_vector[i];          
            test_col = test_vector[i];
            pass_inputs(1'b1, 1'b1,1'b0,test_row,test_col);
        end
        
        testcase = "Filling Column Input Buffer";
        for (int i=0; i < INPUT_BUFF; i++) begin // Fill Column Buffer
            test_row = test_vector[i];          
            test_col = test_vector[i];
            pass_inputs(1'b1, 1'b0,1'b1,test_row,test_col);
        end
        
        
        testcase = "Checking Outputs to ensure they match computed order";
        test_sum = 0;
        
        for (int i=0; i < INPUT_BUFF; i++) begin
            test_row = test_vector[i];
            test_col = test_vector[i];
            
            comp_check(test_row, test_col, test_sum, test_user);
        
            test_sum += test_col*test_row;
            
            repeat(2) @(posedge CLK);  
        end
        
        testphase = "Error Checking";
        reset_dut();
        repeat (5) @(posedge CLK);
        // Check for overflow 
        testcase = "Overflow check";
        test_row = $bitstoshortreal({1'b0,8'hFE,23'b11101110011010110000101});
        test_col = $bitstoshortreal({1'b0,8'h82,23'b01000000000000000000000});
        pass_inputs(1'b1,1'b1,1'b1,test_row,test_col);
      
        test_sum = 0;
        test_user.overflow = 1'b1;
        test_user.underflow = 1'b0;
        
        comp_check(test_row, test_col, test_sum, test_user);
        
        // Check for undeflow
        reset_dut();
        repeat (5) @(posedge CLK);
        testcase = "Underflow check";
        test_row = $bitstoshortreal({1'b0,8'h01,23'b10111101011100011111111});
        test_col = $bitstoshortreal({1'b0,8'h01,23'b11000110101110011011101});
        pass_inputs(1'b1,1'b1,1'b1,test_row,test_col);
      
        test_sum = 0;
        test_user.overflow = 1'b0;
        test_user.underflow = 1'b1;
        
        comp_check(test_row, test_col, test_sum, test_user);
                 
        $display("Testcases Failed/Total Testcases: %d/%d",total_failed_testcases, total_testcases);
        $finish();
    
    end

endmodule

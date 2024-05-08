module test;
  
  reg clk1,clk2;
  integer k;
  
  MIPS32_Pipeline DUT (clk1,clk2);
  
  initial begin
    clk1=0;clk2=0;
    repeat(20)
      begin
        #5 clk1 = 1; #5 clk1 = 0;
        #5 clk2 = 1; #5 clk2 = 0;
     end
  end
  
    initial begin
      for(k=0; k<31; k++)
        begin
          DUT.MEM[k] = k;
          DUT.REG[k] = 0;
        end
      DUT.MEM[0] = 32'h2801000a;
      DUT.MEM[1] = 32'h28020014;
      DUT.MEM[2] = 32'h28030019;
    //  DUT.MEM[3] = 32'h0ce77800; //
   //   DUT.MEM[3] = 32'h0ce77800; //     
      DUT.MEM[4] = 32'h00222000;
      DUT.HALTED = 0;
      DUT.TYPE_BRANCH = 0;
      DUT.PC = 0;
      
     #280
      for(k=0;k<8;k++)
        $display("R%1d - %2d",k,DUT.REG[k]);
       end

endmodule
`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/05/2024 10:28:48 AM
// Design Name: 
// Module Name: router_test_top
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
module router_test_top;
parameter simulation_cycle = 100;
bit SystemClock;
router_io top_io (SystemClock);
test t(top_io);
router dut(
    .reset_n (top_io.reset_n),
    .clock   (top_io.clock),
    .din     (top_io.din),
    .frame_n (top_io.frame_n),
    .valid_n (top_io.valid_n),
    .dout    (top_io.dout),
    .valido_n(top_io.valido_n),
    .frameo_n(top_io.frameo_n) 
);
initial begin
    SystemClock = 0;
end
always #(simulation_cycle/2) SystemClock = !SystemClock;
endmodule

//interface.//
interface router_io(input bit clock);
    logic reset_n;
    logic [15:0] din;
    logic [15:0] frame_n;
    logic [15:0] valid_n;
    logic [15:0] dout;
    logic [15:0] valido_n;
    logic [15:0] frameo_n;
    clocking cb@(posedge clock);
        default input #1 output #1;
        output reset_n;
        output din;
        output frame_n;
        output valid_n;
        input dout;
        input valido_n;
        input frameo_n;
    endclocking: cb
    modport TB(clocking cb, output reset_n);
endinterface
//program test.//
program automatic test (router_io.TB rtr_io);
    bit [3:0] sa;
    bit [3:0] da;
    logic [7:0] payload[$];
    logic [7:0] pkt2cmp_payload[$];
    int NumofCheck = 5;
    int NumofChecked;
    initial begin
        NumofChecked=NumofCheck;
        reset();
        repeat(NumofCheck) begin
        gen();
        fork
            send();
            recv();
        join
            check();
        end
        $display("Num of Right: %d",NumofChecked);
    end
    
//task reset().//
task reset();
    rtr_io.reset_n <= 1'b0;
    rtr_io.cb.frame_n <= 16'hFFFF ; 
    rtr_io.cb.valid_n <= 16'hFFFF ;
    #2; 
    rtr_io.cb.reset_n <= 1'b1;
    repeat(15) @(rtr_io.cb);
endtask: reset

//task gen().//
task gen();
    sa = $random;
    da = $random;
    payload.delete();
    pkt2cmp_payload.delete();
    repeat($urandom_range(2,4))
        payload.push_back($random);
endtask: gen
//task send().//
task send();
    send_addrs();
    send_pad(); 
    send_payload(); 
endtask:send
//task send_addr().//
task send_addrs();
    rtr_io.cb.frame_n[sa] <= 1'b0; 
    rtr_io.cb.din[sa] <= da[0];
    repeat(1) @rtr_io.cb;
    rtr_io.cb.din[sa] <= da[1];
    repeat(1) @rtr_io.cb;
    rtr_io.cb.din[sa] <= da[2];
    repeat(1) @rtr_io.cb;
    rtr_io.cb.din[sa] <= da[3];
    repeat(1) @rtr_io.cb;
endtask: send_addrs
//task send_pad().//
task send_pad();
    rtr_io.cb.valid_n[sa] <= 1'b0;
    
    repeat(2) @rtr_io.cb;
endtask: send_pad
//task send_payload().//
task send_payload();
    rtr_io.cb.valid_n[sa] <= 1'b0; 
    for(int i=0; i<payload.size();i=i+1) begin
        for (int j = 0; j < 8; j=j+1) begin 
            rtr_io.cb.din[sa] <= payload[i][j];    
            if (j==7 && i==payload.size()-1) 
                rtr_io.cb.frame_n[sa] <= 1'b1;
            else
                repeat(1) @rtr_io.cb;
        end
    end
endtask: send_payload
//task recv_payload().//
task recv();
    get_payload();
endtask: recv
//task get_payload.//
task get_payload();
    logic [7:0] tmp;
    @(negedge rtr_io.cb.frameo_n[da]) begin
    for (int i=0; i<payload.size();i=i+1) begin
        for(int j=0;j<8;j=j+1) begin
            if (rtr_io.cb.valido_n==0) 
                tmp[i] =rtr_io.cb.dout[da];
        end
        pkt2cmp_payload.push_back(tmp);      
    end
    end
endtask: get_payload
//task check().//
task check();
    if(compare()) $display("TRUE"); 
    else begin 
        $display("FALSE"); 
        NumofChecked = NumofChecked-1;
    end
endtask:check
//fucntion compare().//
function bit compare();
    for (int i = 0 ; i < payload.size; i=i+1) begin
        if(payload[i] != pkt2cmp_payload[i])
            return 0;
    end
    return 1;
endfunction: compare
endprogram
    

module router(din, frame_n, valid_n, reset_n, clock, dout, frameo_n, valido_n);
input [15:0] din;
input [15:0] frame_n;
input [15:0] valid_n;
input reset_n;
input clock;
output reg [15:0] dout;
output reg [15:0] frameo_n = 16'hffff ;
output reg [15:0] valido_n = 16'hffff;

parameter idle = 2'b00;
parameter get_addr = 2'b01;
parameter pad = 2'b10;
parameter payload = 2'b11;

reg [1:0] state [15:0];
reg [15:0] ready;
reg [3:0] dest [15:0];
reg [2:0] count [15:0];
reg [3:0] buffer [15:0][15:0];
reg [3:0] wp [15:0];
reg [3:0] rp [15:0];
integer k;
genvar i;

generate
    for (i = 0; i < 16; i=i + 1) begin :loop
    always@ (posedge clock) begin           
        if (reset_n == 0) begin
            state[i] <= idle;
            dest[i]<= 0;
            wp[i] <= 0;
            rp[i] <= 0;
        end
        case (state[i])
        idle: begin
            if (frame_n[i] == 0) begin
                dest[i][0] <= din[i];
                count[i] <= 1;
                state[i] <= get_addr;
            end
        end
        get_addr: begin
            dest[i][count[i]] = din[i];
            count[i] = count[i] + 1;
            if (count[i] == 4) begin
                count[i] <= 0;
                state[i] <= pad;
                ready[i] <= 1;
            end
        end
        pad: begin
        if (buffer[dest[i]][rp[dest[i]]] == i) begin
            state[i] <= payload;  
        end
        end     
        payload: begin
        frameo_n[dest[i]] <= 0;
        if (valid_n[i] == 1)
            valido_n[dest[i]] <= 1;
        else begin
            valido_n[dest[i]] <= 0;
            dout[dest[i]] <= din[i];
        end 
        if (frame_n[i] == 1) begin
            frameo_n[dest[i]] <= 1;
            state[i] <= idle;
            rp[dest[i]] = rp[dest[i]] + 1;
        end
        end
        endcase
    end
    end
endgenerate

always@ (posedge clock) begin 
    for (k=0; k<16; k=k+1) begin
        if (ready[k] == 1) begin
            buffer[dest[k]][wp[dest[k]]] = k;
            wp[dest[k]] = wp[dest[k]] + 1;
            ready[k] = 0;
        end
    end            
end

endmodule

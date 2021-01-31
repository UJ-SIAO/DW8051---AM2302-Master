module AM2302_master (
					 clk,
					 rst_n,
					 sfr_rd,
					 sfr_wr,
					 sfr_data_in,
					 sfr_data_out,
					 sfr_addr,
					 sda
						);
						
input clk;
input rst_n;
input [7:0]sfr_addr;
input sfr_rd;
input sfr_wr;
input [7:0]sfr_data_in;
output [7:0]sfr_data_out;
inout sda;

//reg [7:0]sfr_data_out;

wire control_byte_cs;
wire humidityH_cs;
wire humidityL_cs;
wire temperatureH_cs;
wire temperatureL_cs;
wire check_cs;
wire control_byte_wr;
wire humidityH_wr;
wire humidityL_wr;
wire temperatureH_wr;
wire temperatureL_wr;
wire check_wr;
reg  [7:0]control_byte_data;
reg next;

wire pos_sda;
wire neg_sda;
reg isout=1;
reg sda_out;
reg [39:0]data_temp;


reg [2:0]state;
reg [2:0]next_state;
parameter idle=0;
parameter star=1;
parameter response=2;
parameter data=3;
parameter complete=4;

reg active;
reg [31:0]sda_out_counter; 
reg [31:0]sda_counter;
reg [31:0]sda_counter_temp;
reg [31:0]data_count;

wire logic1;
wire logic0;
wire logic_in_range;

assign control_byte_cs 	= (sfr_addr == 8'hE1) ? 1 :0 ;
assign humidityH_cs 	= (sfr_addr == 8'hE2) ? 1 :0 ;
assign humidityL_cs 	= (sfr_addr == 8'hE3) ? 1 :0 ;
assign temperatureH_cs 	= (sfr_addr == 8'hE4) ? 1 :0 ;
assign temperatureL_cs	= (sfr_addr == 8'hE5) ? 1 :0 ;
assign check_cs			= (sfr_addr == 8'hE6) ? 1 :0 ;

assign control_byte_wr	= control_byte_cs & sfr_wr	;
assign humidityH_wr		= humidityH_cs 	  & sfr_wr	;
assign humidityL_wr		= humidityL_cs    & sfr_wr	;
assign temperatureH_wr	= temperatureH_cs & sfr_wr	;
assign temperatureL_wr	= temperatureL_cs & sfr_wr	;
assign check_wr			= check_cs		  & sfr_wr	;

assign sda = isout ? sda_out : 1'bz;

assign logic1 = 4300 < sda_counter_temp && sda_counter_temp <4797;
assign logic0 = 2583 < sda_counter_temp && sda_counter_temp <3134;
assign logic_in_range  = logic1 || logic0 ;

edge_detect sdain(
			   .clk(clk),
			   .rst(rst_n),
			   .data_in(sda),
			   .pos_edge(neg_sda),
			   .neg_edge(pos_sda)
   );
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		sda_counter<=0;
		sda_counter_temp<=0;
	end
	else begin
		if(neg_sda)begin
			sda_counter <= sda_counter + 1;
			sda_counter_temp <= sda_counter;
		end
		else begin
			sda_counter<=0;
			sda_counter_temp<=sda_counter_temp;
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		sda_out_counter<=0;
	else begin
		if(active)begin
			sda_out_counter <= sda_out_counter + 1;
		end
		else
			sda_out_counter<=0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		control_byte_data<=0;
	else
		if(control_byte_wr)
			control_byte_data <= sfr_data_in;
		else
			control_byte_data <= control_byte_data;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		next_state<=idle;
		isout<=0;
		active<=0;
	end
	else begin
		case(state)
			idle:begin
					next_state <=  (control_byte_data == 8'h01) ? star : idle; 
					isout <= 0;
					active<=0;
				end
				
			star:begin
					next_state <=  response ;				
					isout <= (sda_counter >= 36900) ? 0 : 1;
					active<=1;
				end
			response:begin
					next_state <= data;
					isout <= 0;
					active <= 0;
				end
			data:begin
					next_state <= complete;
					isout <= 0;
					active <= 0;					
				end
			complete:begin
					next_state <= idle;
					isout <= 0;
					active <= 0;					
				end
				
				
		endcase
	end
end
// 1ms = 36900 30u=1107
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		state<=idle;
		sda_out<=0;
		next<=1;
		//sfr_data_out<=0;
	end
	else begin
		if(state == idle)begin
			state <= next_state ;
			sda_out <= 1 ;
			next<=1;
		end
		else if(state == star)begin
			if( sda_counter == 32'd38009)
				state <= next_state;
			else if(sda_counter < 32'd36900)
				sda_out <= 0;
		end
		else if (state == response )begin
			if(5535 < sda_counter && sda_counter <6273)
				state <= next_state;
		end
		else if (state == data)begin
			if(data_count==39)
				state <= next_state;
		end
		else if (state==complete)begin
			/*if(control_byte_cs && sfr_rd)
				sfr_data_out <= 8'h11;
			else if (humidityH_cs  && sfr_rd)
				sfr_data_out <= data_temp[39:32];
			else if (humidityL_cs  && sfr_rd)
				sfr_data_out <= data_temp[31:24];
			else if (temperatureH_cs  && sfr_rd)
				sfr_data_out <= data_temp[23:16];
			else if (temperatureL_cs  && sfr_rd)
				sfr_data_out <= data_temp[15:8];
			else if (check_cs  && sfr_rd)
				sfr_data_out <= data_temp[7:0];*/
				next<=0;
			if (sda_counter_temp > 9000)
				state <= next_state;
		end
	end
end

assign sfr_data_out  = 	(next)								? 0		:
						(control_byte_cs   && sfr_rd) 		? 8'h11 :
						(humidityH_cs  	  && sfr_rd)		? data_temp[39:32]:
						(humidityL_cs  	  && sfr_rd)		? data_temp[31:24]:
						(temperatureH_cs  && sfr_rd)		? data_temp[23:16]:
						(temperatureL_cs  && sfr_rd)		? data_temp[15:8]:
						(check_cs  		  && sfr_rd)		? data_temp[7:0]: 0;
						

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		data_count<=0;
	else
		if(state == data)begin
			if(!neg_sda)
				data_count<=data_count+1;
			else
				data_count<=data_count;
		end
		else
			data_count<=0;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		data_temp<=0;
	else
		if(state == data)begin
			if(!neg_sda)begin
				if(logic1)
					data_temp[40-data_count]<=1'b1;
				else if (logic0)
					data_temp[40-data_count]<=1'b0;
				else
					data_temp<=0;
			end
		end
end






endmodule
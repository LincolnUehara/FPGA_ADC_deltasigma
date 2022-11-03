library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use IEEE.std_logic_textio.all;

library work;
use work.custom_adc.all;
use work.custom_tb.all;

-- Define Module for Test Fixture
ENTITY ADC_tf IS  
END ADC_tf;

ARCHITECTURE behavioral OF ADC_tf IS

component sigmadelta
    GENERIC (
        ADC_WIDTH       : integer;
        ACCUM_BITS      : integer;
        LPF_DEPTH_BITS  : integer
    );
    PORT(
        clk         : IN std_logic;	-- 62.5Mhz on Control Demo board
        rstn        : IN std_logic;
        analog_cmp  : IN std_logic;	-- from LVDS buffer or external comparitor
        analog_out  : OUT std_logic;	-- feedback to RC network
        sample_rdy  : OUT std_logic;
        digital_out : OUT std_logic_vector(7 downto 0)   -- connected to LED field on control demo bd.
    );
end component;

-- Inputs to UUT
constant    ADC_WIDTH       : integer := 8;     -- ADC Convertor Bit Precision
constant    ACCUM_BITS      : integer := 10;    -- 2^ACCUM_BITS is decimation rate of accumulator
constant    LPF_DEPTH_BITS  : integer := 3;     -- 2^LPF_DEPTH_BITS is decimation rate of averager
constant    INPUT_TOPOLOGY  : integer := 1;     -- 0: DIRECT: Analog input directly connected to + input of comparitor
                                                -- 1: NETWORK:Analog input connected through R divider to - input of comp.
signal clk           : std_logic := '0';	  
signal counter       : std_logic_vector(15 downto 0):= "0000000000000000";	  
signal rstn          : std_logic := '0';
signal analog_cmp    : std_logic;

-- Outputs from UUT
signal digital_out   : std_logic_vector(7 downto 0);
signal digital_out_i : std_logic_vector(7 downto 0);
signal analog_out    : std_logic;
signal sample_rdy    : std_logic;

constant    period          : time := 16 ns; -- 16ns = 62.5Mhz
constant    FULL_RANGE_BITS : integer := 16;                 -- bits for analog resolution (0-65535)
constant    FULL_RANGE      : integer := 2**FULL_RANGE_BITS;

signal analog_input : integer := 0;
signal integrator   : integer := FULL_RANGE/2;
signal increase     : integer;
signal decrease     : integer;
------------------------------------------------
signal  analog_value            : integer:= 0  ; 
--signal  analog_value1            : integer:= 0  ; 
--signal  analog_value2            : integer:= 0  ; 
--signal  analog_value3           : integer:= 0  ; 
--signal  analog_value4          : integer:= 0  ; 
signal  result                  : integer:= 0  ;
signal  x1                      : integer:= 0  ;
signal  y1                      : integer:= 0  ;
------------------------------------------------	 

BEGIN

-- Instantiate the UUT
-- Please check and add your parameters manually
    --UUT: ADC_top 
    --PORT MAP(
    --    clk_in          => clk, 
    --    rstn            => rstn, 
    --    digital_out     => digital_out_i, 
    --    analog_cmp      => analog_cmp, 
    --    analog_out      => analog_out,
    --sample_rdy      => sample_rdy
    --);

SSD_ADC: entity work.sigmadelta(box_ave)
    GENERIC MAP(
    	ADC_WIDTH       => ADC_WIDTH,
    	ACCUM_BITS      => ACCUM_BITS,
    	LPF_DEPTH_BITS  => LPF_DEPTH_BITS
    )
    PORT MAP(
    	clk             => clk,
    	rstn            => rstn,
    	analog_cmp      => analog_cmp,
    	digital_out     => digital_out_i,
    	analog_out      => analog_out,
    	sample_rdy      => sample_rdy
	);

    digital_out <= digital_out_i when (INPUT_TOPOLOGY = 1) else not digital_out_i;

test_process: process 
begin
    report "Asserting Reset";
    wait for 33 ns;
    report "De-asserting Reset";
	rstn <= '1';
	report "Generating Sawtooth Ramp";
    wait for 2173731 ns;
	report "Simulation Completed with ADC Conversions";
	wait;
end process test_process;

clock_generator: clk <= not clk after 10 ns;

--  simulate analog input and low-pass feedback filter

-- Generate input sawtooth ramp
sawtooth: process
begin
    wait until clk = '1';
    if (analog_input = FULL_RANGE-1) then
        analog_input <= 0;
    else
        analog_input <= analog_input + 1;
    end if;
end process;


-- Calculate the integration delta 
increase <= integer(real(FULL_RANGE - integrator)/real(2**(FULL_RANGE_BITS-5)));   -- create a response time-constant
decrease <= integer(real(integrator)/real(2**(FULL_RANGE_BITS-5)));


-- Integrate the feedback
integrate: process
begin
    wait until clk = '1';
    if (analog_out = '1') then
        integrator <= integrator + increase;
    else
        integrator <= integrator - decrease;
    end if;
end process;


-- Comparator
cmp: process
begin
    wait until clk = '0';
    if (analog_input > integrator) then
        analog_cmp <= '1';
    else
        analog_cmp <= '0';
    end if;
end process;				  


process(clk , rstn)	

begin 	
if (rstn = '0') then	 
    counter <= (others => '0');
elsif (clk'event and clk='1') then
	counter <= counter + '1';  
	
end if;					
end process;

--process (counter)
--begin 
--	if (counter(11) = '1') then
--	analog_value4 <= analog_input; 
--	analog_value3 <= analog_value4;
--	analog_value2 <= analog_value3;
--	analog_value1 <= analog_value2;
--	
--end if;
--end process;

-- monitor digital_out
monitor: process
      VARIABLE lin          : LINE;
begin
 wait until counter(12) = '1';
     if (counter(12)= '1') then
		y1 <= conv_integer(digital_out);
		analog_value <= analog_input;	
		x1 <= analog_value/250;	
		result <= ((y1 - x1)/2);
		
		if (result < 5) then
			write(lin, string'("Time:"));
			write(lin,NOW);
			write(lin, string'(" :  ADC_Conversions Verified and they match"));
			write(lin, string'("  "));
			--write(lin,NOW);
			write(lin, string'(":  Normalized Analog Sample Value ="));
			write(lin, x1);
			write(lin, string'("  "));
			--write(lin,NOW);
			write(lin, string'(" :  Digital output from ADC ="));
			write(lin, y1);
			writeline(output,lin);
		else
			write(lin, string'("Time:"));
			write(lin,NOW);
			write(lin, string'(" :  ADC_Conversions Verified and they DO-NOT match"));
			write(lin, string'("  "));
			--write(lin,NOW);
			write(lin, string'(" :  Normalized Analog Sample Value ="));
			write(lin, x1);
			write(lin, string'("  "));
			--write(lin,NOW);
			write(lin, string'(" :  Digital output from ADC ="));
			write(lin, y1);
			writeline(output,lin);		
		
		end if;  			
	end if;	  
	end process monitor;
						
END behavioral;

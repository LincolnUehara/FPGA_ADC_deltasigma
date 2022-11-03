library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use IEEE.std_logic_textio.all;

library work;
use work.custom_adc.all;

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

-- converts a std_logic_vector into a hex string.
function hstr(slv: std_logic_vector) return string is

variable hexlen: integer;
variable longslv : std_logic_vector(67 downto 0) := (others => '0');
variable hex : string(1 to 16);
variable fourbit : std_logic_vector(3 downto 0);

begin

    hexlen := slv'left/4 + 1;
    -- if (slv'left+1) mod 4 /= 0 then
    -- hexlen := hexlen + 1;
    -- end if;
    longslv(slv'left downto 0) := slv;
    for i in (hexlen -1) downto 0 loop
    
        fourbit := longslv(((i*4)+3) downto (i*4));
        
        case fourbit is
            when "0000" => hex(hexlen -I) := '0';
            when "0001" => hex(hexlen -I) := '1';
            when "0010" => hex(hexlen -I) := '2';
            when "0011" => hex(hexlen -I) := '3';
            when "0100" => hex(hexlen -I) := '4';
            when "0101" => hex(hexlen -I) := '5';
            when "0110" => hex(hexlen -I) := '6';
            when "0111" => hex(hexlen -I) := '7';
            when "1000" => hex(hexlen -I) := '8';
            when "1001" => hex(hexlen -I) := '9';
            when "1010" => hex(hexlen -I) := 'A';
            when "1011" => hex(hexlen -I) := 'B';
            when "1100" => hex(hexlen -I) := 'C';
            when "1101" => hex(hexlen -I) := 'D';
            when "1110" => hex(hexlen -I) := 'E';
            when "1111" => hex(hexlen -I) := 'F';
            when "ZZZZ" => hex(hexlen -I) := 'z';
            when "UUUU" => hex(hexlen -I) := 'u';
            when "XXXX" => hex(hexlen -I) := 'x';
            when others => hex(hexlen -I) := '?';
        end case;
        
    end loop;
    
    return hex(1 to hexlen);
    
end hstr;

-- converts a std_logic_vector into a dec string.
function dstr(slv: std_logic_vector) return string is

variable temp: integer:=0;
variable temp1: integer:=0;
variable idx : integer:=0;
variable dec : string(1 to 8):="        ";

begin

    for i in slv'range loop

        temp := temp *2;

        if slv(i) = '1' then
            temp := temp + 1;
        end if;

    end loop;

    if (temp = 0) then
        dec(8) := '0';
    else
        while (temp > 0) loop
        
            temp1 := temp rem 10;
            temp  := temp / 10;
            idx   := idx + 1;
            
            case temp1 is
                when 0 => dec(8-idx) := '0';
                when 1 => dec(8-idx) := '1';
                when 2 => dec(8-idx) := '2';
                when 3 => dec(8-idx) := '3';
                when 4 => dec(8-idx) := '4';
                when 5 => dec(8-idx) := '5';
                when 6 => dec(8-idx) := '6';
                when 7 => dec(8-idx) := '7';
                when 8 => dec(8-idx) := '8';
                when 9 => dec(8-idx) := '9';
                when others => dec(8-idx) := '?';
            end case;
            
        end loop; 
    end if;

    return dec(8-idx to 8);

end dstr;

--**********************************************************************
--
--	Internal Signals
--
--**********************************************************************
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

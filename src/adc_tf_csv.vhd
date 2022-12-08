LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

USE std.env.finish;
USE std.textio.ALL;

LIBRARY work;
USE work.custom_adc.ALL;
--use work.custom_tb.all; -- Not used here

ENTITY csv_tb IS
END csv_tb;

ARCHITECTURE behavioral OF csv_tb IS

COMPONENT sigmadelta
    GENERIC (
        ADC_WIDTH       : INTEGER;
        ACCUM_BITS      : INTEGER;
        LPF_DEPTH_BITS  : INTEGER
    );
    PORT(
        clk         : IN STD_LOGIC;
        rstn        : IN STD_LOGIC;     -- Reset signal
        analog_cmp  : IN STD_LOGIC;	-- from LVDS buffer or external comparitor
        analog_out  : OUT STD_LOGIC;	-- feedback to RC network
        sample_rdy  : OUT STD_LOGIC;
        digital_out : OUT STD_LOGIC_VECTOR(7 downto 0)   -- connected to LED field on control demo bd.
    );
END COMPONENT;

-- Inputs to UUT
CONSTANT ADC_WIDTH      : INTEGER := 8;  -- ADC Convertor Bit Precision
CONSTANT ACCUM_BITS     : INTEGER := 10; -- 2^ACCUM_BITS is decimation rate of accumulator
CONSTANT LPF_DEPTH_BITS : INTEGER := 3;  -- 2^LPF_DEPTH_BITS is decimation rate of averager
CONSTANT INPUT_TOPOLOGY : INTEGER := 1;  -- 0: DIRECT: Analog input directly connected to + input of comparitor
                                         -- 1: NETWORK:Analog input connected through R divider to - input of comp.
SIGNAL clk           : STD_LOGIC := '0';	  	  
SIGNAL rstn          : STD_LOGIC := '0';
SIGNAL analog_cmp    : STD_LOGIC;

-- Outputs from UUT
SIGNAL digital_out   : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL digital_out_i : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL analog_out    : STD_LOGIC;
SIGNAL sample_rdy    : STD_LOGIC;

CONSTANT DECIMAL_PLACE      : INTEGER := 4;  -- Number of decimal place to be adopted in csv values
CONSTANT FULL_RANGE_BITS    : INTEGER := 16; -- bits for analog resolution (0-65535)
CONSTANT FULL_RANGE         : INTEGER := 2**FULL_RANGE_BITS;
CONSTANT TIME_CONSTANT_BITS : INTEGER := INTEGER(REAL(FULL_RANGE_BITS) * 0.632); -- time-constant response for integrator
                                                                                 -- 0.632 is value for 1 tau

SIGNAL analog_input : INTEGER := 0;
SIGNAL integrator   : INTEGER := FULL_RANGE/2;
SIGNAL increase     : INTEGER;
SIGNAL decrease     : INTEGER;

SIGNAL final_value : BOOLEAN := false; -- Flag to be used between read/write csv file functions

BEGIN

  --*********
  --** ADC **
  --*********
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

  digital_out <= digital_out_i WHEN (INPUT_TOPOLOGY = 1) ELSE NOT digital_out_i;
  
  --****************************************************
  --** Starting whole process by means of reset input **
  --****************************************************
  assert_reset: PROCESS 
  BEGIN
    REPORT "Asserting reset";
    WAIT FOR 40 ns;
    REPORT "De-asserting reset and starting ADC processing with input CSV file...";
    rstn <= '1';
    WAIT;
  END PROCESS assert_reset;

  --***********
  --** CLOCK **
  --***********
  clock_generator: clk <= NOT clk AFTER 10 ns;
  
  --********************************
  --** Integration and Comparator **
  --********************************
  
  -- Calculate the integration delta
  increase <= INTEGER(REAL(FULL_RANGE - integrator)/REAL(2 ** TIME_CONSTANT_BITS));   
  decrease <= INTEGER(REAL(integrator)/REAL(2 ** TIME_CONSTANT_BITS));

  -- Integrate the feedback
  integrate: PROCESS
  BEGIN
    WAIT UNTIL clk = '1';
    IF (analog_out = '1') THEN
        integrator <= integrator + increase;
    ELSE
        integrator <= integrator - decrease;
    END IF;
  END PROCESS integrate;

  -- Comparator
  cmp: PROCESS
  BEGIN
    WAIT UNTIL clk = '0';
    IF (analog_input > integrator) THEN
        analog_cmp <= '1';
    ELSE
        analog_cmp <= '0';
    END IF;
  END PROCESS cmp;				  

  --*******************************
  --** Read and write the values **
  --*******************************
  
  -- Read values from file
  arq_read: PROCESS
    FILE     arq_in   : TEXT;
    VARIABLE buf_line : LINE;
    VARIABLE comma    : CHARACTER := ',';
    VARIABLE value    : REAL;
    VARIABLE read_ok  : BOOLEAN := true;
  BEGIN

    FILE_OPEN(arq_in, "./octave/csv/input.csv", Read_mode);
    readline(arq_in, buf_line);

    WHILE read_ok LOOP
    
      WAIT UNTIL rstn = '1' and sample_rdy = '1';
      
      read(buf_line, value);
      read(buf_line, comma, read_ok); -- read in the space character
      
      -- The read value is multiplied by number of desired decimal places
      -- Be careful to not exceed FULL_RANGE_BITS resolution
      analog_input <= INTEGER(value * (REAL(10 ** DECIMAL_PLACE)));
      
      IF read_ok = false THEN
        REPORT "Reached end of input file.";
        final_value <= true;
      END IF;
    END LOOP;

    FILE_CLOSE(arq_in);
    WAIT;

  END PROCESS arq_read;
  
  -- Write the values to file
  arq_write: PROCESS
    FILE     arq_out  : TEXT;
    VARIABLE buf_line : LINE;
    VARIABLE comma    : CHARACTER := ',';
    VARIABLE value    : REAL;
  BEGIN

    FILE_OPEN(arq_out, "./octave/csv/output.csv", Write_mode);

    laco_a: LOOP
    
      WAIT UNTIL sample_rdy = '1';
      
      -- Analog input comes with 'FULL_RANGE_BITS' resolution , but digital_out comes in
      -- ADC_WIDTH resolution, which is less than the former.
      -- So first multiply by diference between input and output resolution and then 
      -- correct the decimal place.
      value := REAL(conv_integer(digital_out) * (2 ** (FULL_RANGE_BITS - ADC_WIDTH))) / REAL(10 ** DECIMAL_PLACE);
      
      IF NOT final_value THEN
        write(buf_line, to_string(value, "%.4f"));
        write(buf_line, comma);
      END IF;
      
      EXIT laco_a WHEN final_value = true;
      
    END LOOP;
    writeline(arq_out, buf_line);
    
    FILE_CLOSE(arq_out);

    -- Send signal to finish simulation
    finish;

  END PROCESS arq_write;	
  				
END behavioral;

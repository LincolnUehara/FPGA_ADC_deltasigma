library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY adc_filter IS
    GENERIC(
        ADC_WIDTH       : integer := 8;  -- ADC Convertor Bit Precision
        LPF_DEPTH_BITS  : integer := 3   -- 2^LPF_DEPTH_BITS is decimation rate of averager
    );

    PORT(
        --input ports
        clk             : IN std_logic;  -- sample rate clock
        rstn            : IN std_logic;  -- async reset, asserted low
        sample          : IN std_logic;  -- raw_data_in is good on rising edge, 
        raw_data_in     : IN std_logic_vector(ADC_WIDTH-1 downto 0);  -- raw_data input

        --output ports
        ave_data_out    : OUT std_logic_vector(ADC_WIDTH-1 downto 0); -- ave data output
        data_out_valid  : OUT std_logic  -- ave_data_out is valid, single pulse
    );

END adc_filter;

--*********************************************************************
--
-- 'Box' Average - Standard Mean Average Calculation
--
-- Can be modeled as FIR Low-Pass Filter where all coefficients are equal to '1'. 
--
--*********************************************************************
ARCHITECTURE box_ave OF adc_filter IS

    constant    ZERO    : std_logic_vector(LPF_DEPTH_BITS-1 downto 0) := (others => '0'); -- to compare count

    signal accum        : std_logic_vector(ADC_WIDTH+LPF_DEPTH_BITS-1 downto 0); -- accumulator
    signal count        : std_logic_vector(LPF_DEPTH_BITS-1 downto 0);           -- decimation count
    signal raw_data_d1  : std_logic_vector(ADC_WIDTH-1 downto 0);                -- pipeline register

    signal sample_d1    : std_logic;
    signal sample_d2    : std_logic; -- pipeline registers
    signal result_valid : std_logic; -- accumulator result 'valid'
    signal accumulate   : std_logic; -- sample rising edge detected
    signal latch_result : std_logic; -- latch accumulator result

BEGIN

    --***********************************************************************
    --
    -- Rising Edge Detection and data alignment pipelines
    --
    --***********************************************************************
    PROCESS (clk, rstn)
    begin
        if (rstn ='0') then
            sample_d1       <= '0';
            sample_d2       <= '0';
            raw_data_d1     <= (others => '0');
            result_valid    <= '0';
        elsif (clk'event and clk='1') then
            sample_d1       <= sample;       -- capture 'sample' input
            sample_d2       <= sample_d1;    -- delay for edge detection
            raw_data_d1     <= raw_data_in;  -- pipeline 
            result_valid    <= latch_result; -- pipeline for alignment with result
        end if;
    end process;

    accumulate <= sample_d1 and not sample_d2;  -- 'sample' rising_edge detect
    latch_result <= '1' when ((accumulate = '1') and (count = ZERO)) else '0';  -- latch accum. per decimation count

    --***********************************************************************
    --
    -- Accumulator Depth counter
    --
    --***********************************************************************
    PROCESS (clk, rstn)
    begin
        if (rstn ='0') then
            count <= (others => '0');
        elsif (clk'event and clk='1') then
            if (accumulate = '1') then
                count <= count + '1';  -- incr. count per each sample
            end if;
        end if;
    end process;

    --***********************************************************************
    --
    -- Accumulator
    --
    --***********************************************************************
    PROCESS (clk, rstn)
    begin
        if (rstn ='0') then
            accum <= (others => '0');
        elsif (clk'event and clk='1') then
            if (accumulate = '1') then
                if(count = ZERO) then  -- reset accumulator
                    accum <= (others => '0');          
                    accum(ADC_WIDTH-1 downto 0) <= raw_data_d1;  -- prime with first value
                else
                    accum <= accum + raw_data_d1;  -- accumulate
                end if;
            end if;
        end if;
    end process;

    --***********************************************************************
    --
    -- Latch Result
    --
    -- ave = (summation of 'n' samples)/'n'  is right shift when 'n' is power of two
    --
    --***********************************************************************
    PROCESS (clk, rstn)
    begin
        if (rstn ='0') then
            ave_data_out <= (others => '0');
        elsif (clk'event and clk='1') then
            if (latch_result = '1') then  -- at end of decimation period...
                ave_data_out <= accum(ADC_WIDTH+LPF_DEPTH_BITS-1 downto LPF_DEPTH_BITS);  -- ... save accumulator/n result
            end if;
        end if;
    end process;

    --***********************************************************************
    --
    -- output assignments
    --
    --***********************************************************************

    data_out_valid <= result_valid;  -- output assignment

END box_ave;

--*********************************************************************
--
-- Sinc3 Filter
--
--*********************************************************************
ARCHITECTURE sinc3 OF adc_filter IS

    constant    MAX_COUNT   : integer := 10;
    constant    COEF_DEPTH_BITS    : INTEGER := 6;

    signal accum        : std_logic_vector(ADC_WIDTH+COEF_DEPTH_BITS-1 downto 0) := (others => '0'); -- accumulator
    signal count        : integer := 0;           -- decimation count
    signal raw_data_d1  : std_logic_vector(ADC_WIDTH-1 downto 0);                -- pipeline register
    signal raw_data_d2  : std_logic_vector(ADC_WIDTH-1 downto 0);                -- pipeline register

    signal sample_d1    : std_logic;
    signal sample_d2    : std_logic; -- pipeline registers
    signal result_valid : std_logic; -- accumulator result 'valid'
    signal accumulate   : std_logic; -- sample rising edge detected
    signal latch_result : std_logic; -- latch accumulator result

BEGIN

    --***********************************************************************
    --
    -- Rising Edge Detection and data alignment pipelines
    --
    --***********************************************************************
    PROCESS (clk, rstn)
    begin
        if (rstn ='0') then
            sample_d1       <= '0';
            sample_d2       <= '0';
            raw_data_d1     <= (others => '0');
            result_valid    <= '0';
        elsif (clk'event and clk='1') then
            sample_d1       <= sample;        -- capture 'sample' input
            sample_d2       <= sample_d1;     -- delay for edge detection
            raw_data_d1     <= raw_data_in;   -- pipeline 
            result_valid    <= latch_result;  -- pipeline for alignment with result
        end if;
    end process;

    accumulate <= sample_d1 and not sample_d2;  -- 'sample' rising_edge detect
    latch_result <= '1' when ((accumulate = '1') and (count = 0)) else '0';  -- latch accum. per decimation count


    --***********************************************************************
    --
    -- Accumulator Depth counter
    --
    --***********************************************************************
    PROCESS (clk, rstn)
    begin
        if (rstn ='0') then
            count <= 0;
        elsif (clk'event and clk='1') then
            if (accumulate = '1') then
                if (count = (MAX_COUNT-1)) then
                    count <= 0;
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

    --***********************************************************************
    --
    -- Accumulator
    --
    --***********************************************************************
    PROCESS (clk, rstn)
    begin
        if (rstn ='0') then
            accum <= (others => '0');
        elsif (clk'event and clk='1') then
        
            if (accumulate = '1') then
                
                if(count = 0) then
                
                    accum <= (others => '0'); -- reset accumulator
                    accum(ADC_WIDTH-1 downto 0) <= raw_data_d1;
                    
                elsif(count = 1) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 3, accum'length));
                    
                elsif(count = 2) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 6, accum'length));
                    
                elsif(count = 3) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 10, accum'length));
                    
                elsif(count = 4) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 12, accum'length));
                    
                elsif(count = 5) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 12, accum'length));
                    
                elsif(count = 6) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 10, accum'length));
                    
                elsif(count = 7) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 6, accum'length));
                    
                elsif(count = 8) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 3, accum'length));
                    
                elsif(count = 9) then
                
                    accum <= accum + std_logic_vector(to_unsigned(conv_integer(raw_data_d1) * 1, accum'length));
                    
                else
                
                    -- report fail
                    REPORT "Count = 10";
                    
                end if;
                
            end if;
        end if;
    end process;

    --***********************************************************************
    --
    -- Latch Result
    --
    -- ave = (summation of 'n' samples)/'n'  is right shift when 'n' is power of two
    --
    --***********************************************************************
    PROCESS (clk, rstn)
    begin
        if (rstn ='0') then
            ave_data_out <= (others => '0');
        elsif (clk'event and clk='1') then
            if (latch_result = '1') then  -- at end of decimation period...
                
                ave_data_out <= accum(ADC_WIDTH+COEF_DEPTH_BITS-1 downto COEF_DEPTH_BITS);  -- ... save accumulator/n result
                
                -- In case is divided by value different than power of two
                --ave_data_out(ADC_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned((conv_integer(accum) / 64), ADC_WIDTH));
                
            end if;
        end if;
    end process;

    --***********************************************************************
    --
    -- output assignments
    --
    --***********************************************************************
    data_out_valid <= result_valid;  -- output assignment

END sinc3;

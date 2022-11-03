--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

PACKAGE BODY custom_tb IS

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

END custom_tb;

library ieee;
use ieee.std_logic_1164.all;

PACKAGE custom_tb IS

    function hstr(slv: std_logic_vector) return string;
    function dstr(slv: std_logic_vector) return string;

END custom_tb;

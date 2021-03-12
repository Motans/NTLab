library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity comp_mult is
  generic(
    dig_size        :           natural := 18
  );
  port(
    clk             :   in      std_logic;
    reset           :   in      std_logic;
    dstrb           :   in      std_logic;
    in_re           :   in      std_logic_vector(dig_size-1 downto 0);
    in_im           :   in      std_logic_vector(dig_size-1 downto 0);
    out_re          :   out     std_logic_vector(dig_size-1 downto 0);
    out_im          :   out     std_logic_vector(dig_size-1 downto 0)
  );
end comp_mult;

architecture comp_mult_arch of comp_mult is


  begin

    
end comp_mult_arch;
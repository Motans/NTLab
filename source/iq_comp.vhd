library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity iq_comp is
  generic(
    word_len        :           natural := 18;
    max_shift       :           natural := 2
  );
  port( 
    clk             :   in      std_logic;
    reset           :   in      std_logic;
    dstrb           :   in      std_logic;
    prec            :   in      std_logic_vector(max_shift  downto 0);
    din1_re         :   in      std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    din1_im         :   in      std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    dout_re         :   out     std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    dout_im         :   out     std_logic_vector(word_len-1 downto 0)           -- sfix18_En17
  );
end iq_comp;


architecture iq_comp_arch of iq_comp is
    


  begin

end iq_comp_arch;
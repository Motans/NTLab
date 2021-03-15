library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity comp_mult is
  generic(
    word_len        :           natural := 18
  );
  port(
    clk             :   in      std_logic;
    strobe          :   in      std_logic;
    a               :   in      std_logic_vector(word_len-1 downto 0);
    b               :   in      std_logic_vector(word_len-1 downto 0);
    c               :   in      std_logic_vector(word_len-1 downto 0);
    d               :   in      std_logic_vector(word_len-1 downto 0);
    out_re          :   out     std_logic_vector(word_len-1 downto 0);
    out_im          :   out     std_logic_vector(word_len-1 downto 0)
  );
end comp_mult;

architecture comp_mult_arch of comp_mult is
component real_mult is
  generic(
	  word_len        :           natural := 18
  );
  port(
    word_in1        :   in      std_logic_vector(word_len-1 downto 0);
    word_in2        :   in      std_logic_vector(word_len-1 downto 0);
    word_out        :   out     std_logic_vector(word_len-1 downto 0)
  );
end component;

    signal op1          : std_logic_vector(word_len-1 downto 0);        --
    signal op2          : std_logic_vector(word_len-1 downto 0);        -- Real multipliers
    signal prod         : std_logic_vector(word_len-1 downto 0);        --
    
  begin
    mult0 : real_mult
        generic map(word_len)
        port map(op1, op2, prod);

    process(clk, strobe)
        variable state  : integer range 0 to 3;                         -- Multipliers states
        variable ac     : std_logic_vector(word_len-1 downto 0);        -- Res of imag and real
        variable bd     : std_logic_vector(word_len-1 downto 0);        -- part of complex digit
        variable bc     : std_logic_vector(word_len-1 downto 0);        --
      begin    
        if (clk'event and clk = '1') then
            if (strobe = '1') then
                state := 0;
            end if;

            case state is
                when 0 =>
                    op1   <= a;
                    op2   <= c;
                    ac    := prod;
                    state := state + 1;
                when 1 =>
                    op1   <= b;
                    op2   <= d;
                    bd    := prod;
                    state := state + 1;
                when 2 =>
                    op1   <= b;
                    op2   <= c;
                    bc    := prod;
                    state := state + 1;
                when 3 =>
                    op1 <= a;
                    op2 <= d;
                    
                    out_re <= std_logic_vector(
                        signed(ac) - signed(bd));
                    out_im <= std_logic_vector(
                        signed(bc) - signed(prod));
            end case;
        end if;
    end process;
end comp_mult_arch;
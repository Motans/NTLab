library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_bench is
end test_bench;


architecture test_bench_arch of test_bench is
procedure clk_event(signal clk: out std_logic; constant FREQ: real; constant N: natural) is
    constant PERIOD    : time := 1 sec / FREQ;        -- Full period
    constant HIGH_TIME : time := PERIOD / 2;          -- High time
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME

  begin
    for i in 0 to N-1 loop
        clk <= '1';
        wait for HIGH_TIME;
        clk <= '0';
        wait for LOW_TIME;
    end loop;
end procedure;

component comp_mult is
    generic(
      word_len        :           natural
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
end component;

component shiftr is
    generic(
      word_len    :           natural := 18;
      prec_len    :           natural := 3
    );
    port( 
      clk         :   in      std_logic;
      prec        :   in      std_logic_vector(prec_len-1 downto 0);
      word_in     :   in      std_logic_vector(word_len-1 downto 0);
      word_out    :   out     std_logic_vector(word_len-1 downto 0)
    );
end component;

    constant WORD_LEN   : integer := 18;
    constant PREC_LEN   : integer := 3;
    
    signal clk      :   std_logic;
    signal strobe   :   std_logic;
    signal a        :   std_logic_vector(WORD_LEN-1 downto 0);
    signal b        :   std_logic_vector(WORD_LEN-1 downto 0);
    signal c        :   std_logic_vector(WORD_LEN-1 downto 0);
    signal d        :   std_logic_vector(WORD_LEN-1 downto 0);

    signal res_re   :   std_logic_vector(WORD_LEN-1 downto 0);
    signal res_im   :   std_logic_vector(WORD_LEN-1 downto 0);

    signal prec     :   std_logic_vector(PREC_LEN-1 downto 0);
    signal word_in  :   std_logic_vector(WORD_LEN-1 downto 0);
    signal word_out :   std_logic_vector(WORD_LEN-1 downto 0);

  begin
    clk_event(clk, 100.0, 5);
    strobe <= '1', '0' after 10 ms;
    a <= std_logic_vector(
        to_signed(26214, WORD_LEN));
    b <= std_logic_vector(
        to_signed(78643, WORD_LEN));
    c <= std_logic_vector(
        to_signed(52429, WORD_LEN));
    d <= std_logic_vector(
        to_signed(26214, WORD_LEN));
    comp_mult0: comp_mult
        generic map(WORD_LEN)
        port map(clk, strobe, a, b, c, d, res_re, res_im);


    word_in <= "010000000000000000";
    prec    <= "000", 
               "001" after 10 ms,
               "010" after 20 ms,
               "011" after 30 ms,
               "111" after 40 ms;

    shiftr0: shiftr
        generic map(WORD_LEN, PREC_LEN)
        port map(clk, prec, word_in, word_out);
    

end test_bench_arch;
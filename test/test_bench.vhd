library ieee;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;

entity test_bench is
end test_bench;


architecture test_bench_arch of test_bench is
procedure clk_event(signal clk: out std_logic; 
                    constant FREQ: real; 
                    constant N: natural) is
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

procedure strobe_event(signal strobe: out std_logic;
                       constant FREQ: real;
                       constant DURATION : time;
                       constant N: natural) is
    constant PERIOD    : time := 1 sec / FREQ;          -- Full period
    constant HIGH_TIME : time := DURATION;              -- High time
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;    -- Low time; always >= HIGH_TIME
  begin
    for i in 0 to N-1 loop
        strobe <= '1';
        wait for HIGH_TIME;
        strobe <= '0';
        wait for LOW_TIME;
    end loop;
end procedure;

component nco is
  generic(
    dig_size    :       natural;
    acc_size    :       natural;
    quant_size  :       natural;
    F_s         :       natural
  );
  port(
    clk         :   in  std_logic;
    reset       :   in  std_logic;
    phase_inc   :   in  std_logic_vector(acc_size-1 downto 0);
    sin_out     :   out std_logic_vector(dig_size-1 downto 0);
    cos_out     :   out std_logic_vector(dig_size-1 downto 0)
  );
end component;

component iq_comp is
  generic(
    word_len        :           natural;
    prec_len        :           natural;
    resize_param    :           natural
  );
  port( 
    clk             :   in      std_logic;
    reset           :   in      std_logic;
    dstrb           :   in      std_logic;
    prec            :   in      std_logic_vector(prec_len-1 downto 0);
    din1_re         :   in      std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    din1_im         :   in      std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    dout_re         :   out     std_logic_vector(word_len-1 downto 0);          -- sfix18_En17
    dout_im         :   out     std_logic_vector(word_len-1 downto 0)           -- sfix18_En17
  );
end component;

    constant    outfilename0    :   string  := "./matlab/re_in.txt";
    constant    outfilename1    :   string  := "./matlab/im_in.txt";
    constant    outfilename2    :   string  := "./matlab/re_out.txt";
    constant    outfilename3    :   string  := "./matlab/im_out.txt";

    file        outfile0        :   TEXT    open write_mode is outfilename0;
    file        outfile1        :   TEXT    open write_mode is outfilename1;
    file        outfile2        :   TEXT    open write_mode is outfilename2;
    file        outfile3        :   TEXT    open write_mode is outfilename3;

    constant    WORD_LEN        :   integer := 18;
    constant    PREC_LEN        :   integer := 3;
    constant    RESIZE_PARAM    :   integer := 16;
    constant    DIG_SIZE        :   integer := 18;
    constant    ACC_SIZE        :   integer := 16;
    constant    QUANT_SIZE      :   integer := 12;
    constant    F_s             :   integer := 44100;

    constant    FREQ            :   real    := 1000.0;
    constant    N               :   natural := 2**14;
    
    signal      clk             :   std_logic;
    signal      strobe_cos      :   std_logic;
    signal      clk_iq          :   std_logic;
    signal      strobe          :   std_logic;
    signal      reset           :   std_logic := '0';

    signal      prec            :   std_logic_vector(PREC_LEN-1 downto 0);
    signal      phase_inc       :   std_logic_vector(ACC_SIZE-1 downto 0);
    signal      sin_x           :   std_logic_vector(DIG_SIZE-1 downto 0);
    signal      cos_x           :   std_logic_vector(DIG_SIZE-1 downto 0);
    signal      cos_redux       :   std_logic_vector(DIG_SIZE-1 downto 0) := (others => '0');

    signal      dout_re         :   std_logic_vector(DIG_SIZE-1 downto 0);
    signal      dout_im         :   std_logic_vector(DIG_SIZE-1 downto 0);

  begin
    clk_event(clk, FREQ, 16*N);
    strobe_event(strobe, FREQ/16.0, 0.5 sec / FREQ, N);
    phase_inc <= std_logic_vector(
        to_unsigned(512, ACC_SIZE));
    prec <= std_logic_vector(to_unsigned(2, PREC_LEN));

    nco0: nco
        generic map( DIG_SIZE,
                     ACC_SIZE,
                     QUANT_SIZE,
                     F_s)
        port map(strobe, reset, phase_inc, sin_x, cos_x);
	
    redux_cos: process(clk_iq, reset)
      begin
	    if reset = '1' then
		      cos_redux <= (others => '0');
      elsif(clk_iq'event and clk_iq = '1') then
          cos_redux <= std_logic_vector(shift_right(signed(cos_x),1));
      end if;
    end process redux_cos;	
    
    clk_iq <= clk;
    iq_comp0: iq_comp
        generic map( WORD_LEN,
                     PREC_LEN,
                     RESIZE_PARAM)
        port map(clk_iq, reset, strobe, prec, cos_redux, sin_x, dout_re, dout_im);

    RC: process(strobe)
        variable l : line;
      begin
        if(strobe'event and strobe = '0') then
            write(l,to_integer(signed(cos_redux)));
            writeline(outfile0,l);

            write(l,to_integer(signed(sin_x)));
            writeline(outfile1,l);

            write(l,to_integer(signed(dout_re)));
            writeline(outfile2, l);

            write(l,to_integer(signed(dout_im)));
            writeline(outfile3,l);
        end if;
    end process RC;
end test_bench_arch;
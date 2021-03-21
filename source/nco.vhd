library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity nco is
  generic(
    dig_size    :       natural := 16;
    acc_size    :       natural := 16;
    quant_size  :       natural := 12;
    F_s         :       natural := 44100
  );
  port(
    clk         :   in  std_logic;
    reset       :   in  std_logic;
    phase_inc   :   in  std_logic_vector(acc_size-1 downto 0);
    sin_out     :   out std_logic_vector(dig_size-1 downto 0);
    cos_out     :   out std_logic_vector(dig_size-1 downto 0)
  );
end nco;


architecture nco_arch of nco is
    subtype val_type is integer range -2**(dig_size-1) to 2**(dig_size-1) - 1;
    constant TABLE_SIZE : integer := 2**quant_size/4;

    type table_array is array (0 to TABLE_SIZE-1) of val_type;

    constant LUT : table_array := (
           0,     201,     402,     603,     804,    1005,    1206,    1407,    1608,    1809,    2010,    2211,
        2412,    2613,    2814,    3015,    3216,    3417,    3618,    3819,    4020,    4221,    4422,    4623,
        4824,    5025,    5226,    5427,    5628,    5828,    6029,    6230,    6431,    6632,    6833,    7033,
        7234,    7435,    7636,    7836,    8037,    8238,    8438,    8639,    8840,    9040,    9241,    9441,
        9642,    9842,   10043,   10243,   10444,   10644,   10844,   11045,   11245,   11445,   11646,   11846,
       12046,   12246,   12447,   12647,   12847,   13047,   13247,   13447,   13647,   13847,   14047,   14247,
       14447,   14646,   14846,   15046,   15246,   15445,   15645,   15845,   16044,   16244,   16443,   16643,
       16842,   17041,   17241,   17440,   17639,   17838,   18038,   18237,   18436,   18635,   18834,   19033,
       19232,   19431,   19629,   19828,   20027,   20226,   20424,   20623,   20821,   21020,   21218,   21417,
       21615,   21813,   22012,   22210,   22408,   22606,   22804,   23002,   23200,   23398,   23595,   23793,
       23991,   24189,   24386,   24584,   24781,   24979,   25176,   25373,   25570,   25768,   25965,   26162,
       26359,   26556,   26752,   26949,   27146,   27343,   27539,   27736,   27932,   28129,   28325,   28521,
       28718,   28914,   29110,   29306,   29502,   29698,   29893,   30089,   30285,   30480,   30676,   30871,
       31067,   31262,   31457,   31652,   31847,   32042,   32237,   32432,   32627,   32822,   33016,   33211,
       33405,   33600,   33794,   33988,   34182,   34376,   34570,   34764,   34958,   35152,   35345,   35539,
       35733,   35926,   36119,   36312,   36506,   36699,   36892,   37085,   37277,   37470,   37663,   37855,
       38048,   38240,   38432,   38625,   38817,   39009,   39200,   39392,   39584,   39776,   39967,   40159,
       40350,   40541,   40732,   40923,   41114,   41305,   41496,   41687,   41877,   42068,   42258,   42448,
       42639,   42829,   43019,   43208,   43398,   43588,   43778,   43967,   44156,   44346,   44535,   44724,
       44913,   45102,   45290,   45479,   45667,   45856,   46044,   46232,   46420,   46608,   46796,   46984,
       47172,   47359,   47547,   47734,   47921,   48108,   48295,   48482,   48669,   48855,   49042,   49228,
       49415,   49601,   49787,   49973,   50159,   50344,   50530,   50715,   50901,   51086,   51271,   51456,
       51641,   51826,   52010,   52195,   52379,   52563,   52747,   52931,   53115,   53299,   53483,   53666,
       53850,   54033,   54216,   54399,   54582,   54764,   54947,   55130,   55312,   55494,   55676,   55858,
       56040,   56222,   56403,   56585,   56766,   56947,   57128,   57309,   57490,   57670,   57851,   58031,
       58211,   58392,   58571,   58751,   58931,   59110,   59290,   59469,   59648,   59827,   60006,   60185,
       60363,   60542,   60720,   60898,   61076,   61254,   61431,   61609,   61786,   61964,   62141,   62318,
       62495,   62671,   62848,   63024,   63200,   63376,   63552,   63728,   63904,   64079,   64254,   64430,
       64605,   64780,   64954,   65129,   65303,   65477,   65652,   65825,   65999,   66173,   66346,   66520,
       66693,   66866,   67039,   67211,   67384,   67556,   67729,   67901,   68073,   68244,   68416,   68587,
       68759,   68930,   69101,   69271,   69442,   69612,   69783,   69953,   70123,   70292,   70462,   70632,
       70801,   70970,   71139,   71308,   71476,   71645,   71813,   71981,   72149,   72317,   72485,   72652,
       72819,   72986,   73153,   73320,   73487,   73653,   73819,   73985,   74151,   74317,   74482,   74648,
       74813,   74978,   75143,   75307,   75472,   75636,   75800,   75964,   76128,   76292,   76455,   76618,
       76781,   76944,   77107,   77269,   77432,   77594,   77756,   77917,   78079,   78240,   78402,   78563,
       78724,   78884,   79045,   79205,   79365,   79525,   79685,   79844,   80004,   80163,   80322,   80481,
       80639,   80798,   80956,   81114,   81272,   81429,   81587,   81744,   81901,   82058,   82215,   82371,
       82527,   82684,   82839,   82995,   83151,   83306,   83461,   83616,   83771,   83925,   84080,   84234,
       84388,   84542,   84695,   84848,   85002,   85155,   85307,   85460,   85612,   85764,   85916,   86068,
       86220,   86371,   86522,   86673,   86824,   86974,   87124,   87275,   87425,   87574,   87724,   87873,
       88022,   88171,   88320,   88468,   88616,   88764,   88912,   89060,   89207,   89354,   89501,   89648,
       89795,   89941,   90087,   90233,   90379,   90524,   90670,   90815,   90960,   91104,   91249,   91393,
       91537,   91681,   91824,   91968,   92111,   92254,   92397,   92539,   92681,   92823,   92965,   93107,
       93248,   93390,   93530,   93671,   93812,   93952,   94092,   94232,   94372,   94511,   94650,   94789,
       94928,   95067,   95205,   95343,   95481,   95618,   95756,   95893,   96030,   96167,   96303,   96439,
       96576,   96711,   96847,   96982,   97117,   97252,   97387,   97521,   97656,   97790,   97923,   98057,
       98190,   98323,   98456,   98589,   98721,   98853,   98985,   99117,   99248,   99380,   99511,   99641,
       99772,   99902,  100032,  100162,  100292,  100421,  100550,  100679,  100807,  100936,  101064,  101192,
      101320,  101447,  101574,  101701,  101828,  101954,  102081,  102207,  102332,  102458,  102583,  102708,
      102833,  102957,  103082,  103206,  103330,  103453,  103577,  103700,  103822,  103945,  104067,  104190,
      104311,  104433,  104554,  104676,  104796,  104917,  105037,  105158,  105278,  105397,  105517,  105636,
      105755,  105873,  105992,  106110,  106228,  106345,  106463,  106580,  106697,  106814,  106930,  107046,
      107162,  107278,  107393,  107508,  107623,  107738,  107852,  107966,  108080,  108194,  108307,  108420,
      108533,  108646,  108758,  108870,  108982,  109093,  109205,  109316,  109427,  109537,  109647,  109758,
      109867,  109977,  110086,  110195,  110304,  110412,  110520,  110628,  110736,  110844,  110951,  111058,
      111164,  111271,  111377,  111483,  111588,  111694,  111799,  111904,  112008,  112112,  112216,  112320,
      112424,  112527,  112630,  112733,  112835,  112937,  113039,  113141,  113242,  113343,  113444,  113545,
      113645,  113745,  113845,  113944,  114044,  114143,  114241,  114340,  114438,  114536,  114633,  114731,
      114828,  114925,  115021,  115117,  115213,  115309,  115405,  115500,  115595,  115689,  115784,  115878,
      115972,  116065,  116158,  116251,  116344,  116437,  116529,  116621,  116712,  116804,  116895,  116986,
      117076,  117166,  117256,  117346,  117436,  117525,  117614,  117702,  117791,  117879,  117966,  118054,
      118141,  118228,  118315,  118401,  118487,  118573,  118659,  118744,  118829,  118914,  118998,  119082,
      119166,  119250,  119333,  119416,  119499,  119581,  119663,  119745,  119827,  119908,  119989,  120070,
      120150,  120231,  120311,  120390,  120470,  120549,  120627,  120706,  120784,  120862,  120940,  121017,
      121094,  121171,  121248,  121324,  121400,  121475,  121551,  121626,  121701,  121775,  121849,  121923,
      121997,  122070,  122143,  122216,  122289,  122361,  122433,  122505,  122576,  122647,  122718,  122788,
      122858,  122928,  122998,  123067,  123136,  123205,  123274,  123342,  123410,  123477,  123544,  123611,
      123678,  123745,  123811,  123877,  123942,  124007,  124072,  124137,  124201,  124266,  124329,  124393,
      124456,  124519,  124582,  124644,  124706,  124768,  124829,  124890,  124951,  125012,  125072,  125132,
      125192,  125251,  125310,  125369,  125428,  125486,  125544,  125601,  125659,  125716,  125772,  125829,
      125885,  125941,  125996,  126052,  126107,  126161,  126216,  126270,  126324,  126377,  126430,  126483,
      126536,  126588,  126640,  126692,  126743,  126794,  126845,  126895,  126946,  126996,  127045,  127094,
      127143,  127192,  127241,  127289,  127336,  127384,  127431,  127478,  127525,  127571,  127617,  127663,
      127708,  127753,  127798,  127843,  127887,  127931,  127974,  128018,  128061,  128103,  128146,  128188,
      128230,  128271,  128312,  128353,  128394,  128434,  128474,  128514,  128553,  128592,  128631,  128669,
      128707,  128745,  128783,  128820,  128857,  128894,  128930,  128966,  129002,  129037,  129072,  129107,
      129142,  129176,  129210,  129244,  129277,  129310,  129343,  129375,  129407,  129439,  129470,  129502,
      129532,  129563,  129593,  129623,  129653,  129682,  129711,  129740,  129768,  129797,  129824,  129852,
      129879,  129906,  129933,  129959,  129985,  130011,  130036,  130061,  130086,  130110,  130134,  130158,
      130182,  130205,  130228,  130251,  130273,  130295,  130317,  130338,  130359,  130380,  130400,  130420,
      130440,  130460,  130479,  130498,  130517,  130535,  130553,  130571,  130588,  130605,  130622,  130639,
      130655,  130671,  130686,  130701,  130716,  130731,  130745,  130759,  130773,  130786,  130800,  130812,
      130825,  130837,  130849,  130860,  130872,  130883,  130893,  130904,  130914,  130923,  130933,  130942,
      130951,  130959,  130967,  130975,  130983,  130990,  130997,  131003,  131010,  131016,  131022,  131027,
      131032,  131037,  131041,  131045,  131049,  131053,  131056,  131059,  131062,  131064,  131066,  131068,
      131069,  131070,  131071,  131071
    );
  begin
    sin_gen: process(clk, reset)
        variable acc        : unsigned(acc_size-1 downto 0) := (others => '0');

        variable addr       : unsigned(quant_size-1 downto 0);
        variable real_addr  : integer range 0 to 2*TABLE_SIZE - 1;
        variable sin_addr   : integer range 0 to TABLE_SIZE;
        variable cos_addr   : integer range 0 to TABLE_SIZE;

        variable sin_sign   : std_logic;                                -- 0 is +
        variable cos_sign   : std_logic;                                -- 1 is -

        variable sin_val    : signed(dig_size-1 downto 0);
        variable cos_val    : signed(dig_size-1 downto 0);
        variable cos_buf    : std_logic_vector(dig_size-1 downto 0) := (others => '0');
      begin 
        if (reset = '1') then
            acc     := (others => '0');
            addr    := (others => '0');
            sin_out <= (others => '0');
        elsif (clk'event and clk = '1') then

            addr := acc(acc_size-1 downto acc_size - quant_size);       --quantization
            acc  := acc + unsigned(phase_inc);

            if (to_integer(addr) < 2*TABLE_SIZE) then
                real_addr   := to_integer(addr);
                sin_sign    := '0';
            else
                real_addr   := to_integer(addr) - 2*TABLE_SIZE;
                sin_sign    := '1';
            end if;

            if (real_addr < TABLE_SIZE+1) then
                cos_sign := '0';
            else
                real_addr := 2*TABLE_SIZE - real_addr;
                cos_sign := '1';
            end if;
            
            sin_addr := real_addr;
            cos_addr := TABLE_SIZE - real_addr;

            if (sin_addr = TABLE_SIZE) then
                sin_val := to_signed(2**(dig_size-1) - 1, dig_size);
            else
                sin_val := to_signed(LUT(sin_addr), dig_size);
            end if;

            if (cos_addr = TABLE_SIZE) then
                cos_val := to_signed(2**(dig_size-1) - 1, dig_size);
            else
                cos_val := to_signed(LUT(cos_addr), dig_size);
            end if;

            if (sin_sign = '1') then
                sin_val := -sin_val;
            end if;

            if ('1' = (sin_sign xor cos_sign)) then
                cos_val := -cos_val;
            end if;
            
            sin_out <= std_logic_vector(sin_val);
            cos_out <= cos_buf;
            cos_buf := std_logic_vector(cos_val / to_signed(2, dig_size));
        end if;
    end process;
end nco_arch;
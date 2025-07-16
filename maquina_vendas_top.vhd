library ieee;
use ieee.std_logic_1164.all;

entity maquina_vendas_top is
    port (
        clk     : in  std_logic;
        reset_n : in  std_logic;

        m       : in  std_logic;
        v       : in  std_logic_vector(7 downto 0);
        r1      : in  std_logic_vector(7 downto 0);
        r2      : in  std_logic_vector(7 downto 0);
        b1      : in  std_logic;
        b2      : in  std_logic;

        f1      : out std_logic;
        f2      : out std_logic;
        nt      : out std_logic;
        vt      : out std_logic_vector(7 downto 0)
    );
end entity maquina_vendas_top;

architecture structure of maquina_vendas_top is

    -- Sinais internos para conectar BO e BC
    signal s_load_credit       : std_logic;
    signal s_sel_next_credit   : std_logic_vector(1 downto 0);
    signal s_sel_product_cost  : std_logic;
    signal s_credit            : std_logic_vector(7 downto 0);
    signal s_can_buy           : std_logic;
    signal s_f1, s_f2, s_nt    : std_logic;
    signal s_vt                : std_logic_vector(7 downto 0); -- Apenas para conectar vt_o do BO à saída externa

    -- Componente do Bloco Operativo
    component maquina_vendas_bo
        port (
            clk                 : in  std_logic;
            reset_n             : in  std_logic;
            m                   : in  std_logic;
            v                   : in  std_logic_vector(7 downto 0);
            r1                  : in  std_logic_vector(7 downto 0);
            r2                  : in  std_logic_vector(7 downto 0);
            b1                  : in  std_logic;
            b2                  : in  std_logic;
            load_credit_i       : in  std_logic;
            sel_next_credit_i   : in  std_logic_vector(1 downto 0);
            sel_product_cost_i  : in  std_logic;
            credit_o            : out std_logic_vector(7 downto 0);
            can_buy_o           : out std_logic;
            vt_o                : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Componente do Bloco de Controle
    component maquina_vendas_bc
        port (
            clk                 : in  std_logic;
            reset_n             : in  std_logic;
            m                   : in  std_logic;
            b1                  : in  std_logic;
            b2                  : in  std_logic;
            can_buy_i           : in  std_logic;
            credit_i            : in  std_logic_vector(7 downto 0);
            load_credit_o       : out std_logic;
            sel_next_credit_o   : out std_logic_vector(1 downto 0);
            sel_product_cost_o  : out std_logic;
            f1_o                : out std_logic;
            f2_o                : out std_logic;
            nt_o                : out std_logic
        );
    end component;

begin

    -- Instanciação do Bloco Operativo
    BO_INST : maquina_vendas_bo
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            m                   => m,
            v                   => v,
            r1                  => r1,
            r2                  => r2,
            b1                  => b1,
            b2                  => b2,
            load_credit_i       => s_load_credit,
            sel_next_credit_i   => s_sel_next_credit,
            sel_product_cost_i  => s_sel_product_cost,
            credit_o            => s_credit,
            can_buy_o           => s_can_buy,
            vt_o                => s_vt
        );

    -- Instanciação do Bloco de Controle
    BC_INST : maquina_vendas_bc
        port map (
            clk                 => clk,
            reset_n             => reset_n,
            m                   => m,
            b1                  => b1,
            b2                  => b2,
            can_buy_i           => s_can_buy,
            credit_i            => s_credit,
            load_credit_o       => s_load_credit,
            sel_next_credit_o   => s_sel_next_credit,
            sel_product_cost_o  => s_sel_product_cost,
            f1_o                => s_f1,
            f2_o                => s_f2,
            nt_o                => s_nt
        );

    -- Conectando as saídas internas às saídas externas da entidade top
    f1 <= s_f1;
    f2 <= s_f2;
    nt <= s_nt;
    vt <= s_vt; -- O valor de troco é a saída direta do BO

end architecture structure;
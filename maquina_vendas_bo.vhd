library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity maquina_vendas_bo is
    port (
        clk                 : in  std_logic;
        reset_n             : in  std_logic; -- Reset Ativo Baixo
        m                   : in  std_logic; -- Moeda detectada (1 ciclo de clock)
        v                   : in  std_logic_vector(7 downto 0); -- Valor da moeda
        r1                  : in  std_logic_vector(7 downto 0); -- Custo produto 1
        r2                  : in  std_logic_vector(7 downto 0); -- Custo produto 2
        b1                  : in  std_logic; -- Botão produto 1 (1 ciclo de clock)
        b2                  : in  std_logic; -- Botão produto 2 (1 ciclo de clock)

        -- Sinais de controle do Bloco de Controle (BC)
        load_credit_i       : in  std_logic; -- Carrega novo valor no registrador de crédito
        sel_next_credit_i   : in  std_logic_vector(1 downto 0); -- 00: add v, 01: sub r1/r2, 10: reset to 0
        sel_product_cost_i  : in  std_logic; -- 0: r1, 1: r2

        -- Saídas para o Bloco de Controle (BC) ou externas
        credit_o            : out std_logic_vector(7 downto 0); -- Crédito atual
        can_buy_o           : out std_logic; -- Indica se tem crédito suficiente
        vt_o                : out std_logic_vector(7 downto 0) -- Valor do troco
    );
end entity maquina_vendas_bo;

architecture rtl of maquina_vendas_bo is
    signal current_credit_s : unsigned(7 downto 0) := (others => '0');
    signal next_credit_s    : unsigned(7 downto 0);
    signal product_cost_s   : unsigned(7 downto 0);
    signal sum_credit_v_s   : unsigned(7 downto 0);
    signal sub_credit_cost_s : unsigned(7 downto 0);
    signal temp_vt_s        : unsigned(7 downto 0);
begin

    -- Registrador de Crédito
    process (clk, reset_n)
    begin
        if reset_n = '0' then
            current_credit_s <= (others => '0');
        elsif rising_edge(clk) then
            if load_credit_i = '1' then
                current_credit_s <= next_credit_s;
            end if;
        end if;
    end process;

    credit_o <= std_logic_vector(current_credit_s);

    -- Somador: Adiciona valor da moeda
    sum_credit_v_s <= current_credit_s + unsigned(v);

    -- Multiplexador de Custo do Produto
    with sel_product_cost_i select
        product_cost_s <= unsigned(r1) when '0',
                          unsigned(r2) when others;

    -- Subtrator: Subtrai custo do produto
    sub_credit_cost_s <= current_credit_s - product_cost_s;

    -- Multiplexador para o próximo valor do crédito (next_credit_s)
    with sel_next_credit_i select
        next_credit_s <= sum_credit_v_s      when "00", -- Adicionar moeda
                         sub_credit_cost_s   when "01", -- Subtrair custo do produto
                         (others => '0')     when "10", -- Zera crédito (para troco)
                         current_credit_s    when others; -- Manter (estado IDLE, por exemplo)

    -- Comparador: Verifica se tem crédito suficiente
    can_buy_o <= '1' when current_credit_s >= product_cost_s else '0';

    -- Saída de Troco (vt_o)
    -- O troco é o valor final do current_credit_s após a compra.
    -- O BC deve controlar quando esse valor é relevante (via nt_o)
    vt_o <= std_logic_vector(current_credit_s);

end architecture rtl;
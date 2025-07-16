library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Para comparações de unsigned se necessário para credit_o

entity maquina_vendas_bc is
    port (
        clk                 : in  std_logic;
        reset_n             : in  std_logic;

        -- Entradas do BO ou externas
        m                   : in  std_logic;
        b1                  : in  std_logic;
        b2                  : in  std_logic;
        can_buy_i           : in  std_logic; -- do BO
        credit_i            : in  std_logic_vector(7 downto 0); -- do BO para verificar troco

        -- Saídas de controle para o BO
        load_credit_o       : out std_logic;
        sel_next_credit_o   : out std_logic_vector(1 downto 0);
        sel_product_cost_o  : out std_logic;

        -- Saídas externas da máquina de vendas
        f1_o                : out std_logic;
        f2_o                : out std_logic;
        nt_o                : out std_logic -- Necessidade de troco
    );
end entity maquina_vendas_bc;

architecture fsm of maquina_vendas_bc is

    -- Definição dos estados
    type state_type is (IDLE, COIN_DETECTED,
                        CHECKING_B1, CHECKING_B2,
                        DISPENSING_P1, DISPENSING_P2,
                        GIVING_CHANGE);
    signal current_state, next_state : state_type;

begin

    -- Lógica Sequencial (Transições de Estado)
    process (clk, reset_n)
    begin
        if reset_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Lógica Combinacional (Próximo Estado e Saídas)
    process (current_state, m, b1, b2, can_buy_i, credit_i)
    begin
        -- Default values (minimize latches)
        next_state <= current_state;
        load_credit_o <= '0';
        sel_next_credit_o <= "11"; -- Keep current credit
        sel_product_cost_o <= '0'; -- Default to r1, will be set appropriately
        f1_o <= '0';
        f2_o <= '0';
        nt_o <= '0';

        case current_state is
            when IDLE =>
                if m = '1' then
                    next_state <= COIN_DETECTED;
                elsif b1 = '1' then
                    next_state <= CHECKING_B1;
                    sel_product_cost_o <= '0'; -- Seleciona r1 para comparação
                elsif b2 = '1' then
                    next_state <= CHECKING_B2;
                    sel_product_cost_o <= '1'; -- Seleciona r2 para comparação
                else
                    next_state <= IDLE;
                end if;

            when COIN_DETECTED =>
                load_credit_o <= '1';
                sel_next_credit_o <= "00"; -- Adiciona valor da moeda
                next_state <= IDLE; -- Retorna a IDLE após processar a moeda

            when CHECKING_B1 =>
                sel_product_cost_o <= '0'; -- Garante que r1 está selecionado para comparação
                if can_buy_i = '1' then
                    next_state <= DISPENSING_P1;
                else
                    next_state <= IDLE; -- Crédito insuficiente, volta a IDLE
                end if;

            when CHECKING_B2 =>
                sel_product_cost_o <= '1'; -- Garante que r2 está selecionado para comparação
                if can_buy_i = '1' then
                    next_state <= DISPENSING_P2;
                else
                    next_state <= IDLE; -- Crédito insuficiente, volta a IDLE
                end if;

            when DISPENSING_P1 =>
                f1_o <= '1'; -- Ativa a saída do produto
                load_credit_o <= '1';
                sel_next_credit_o <= "01"; -- Subtrai custo do produto (r1)
                sel_product_cost_o <= '0'; -- Garante que r1 é subtraído
                next_state <= GIVING_CHANGE;

            when DISPENSING_P2 =>
                f2_o <= '1'; -- Ativa a saída do produto
                load_credit_o <= '1';
                sel_next_credit_o <= "01"; -- Subtrai custo do produto (r2)
                sel_product_cost_o <= '1'; -- Garante que r2 é subtraído
                next_state <= GIVING_CHANGE;

            when GIVING_CHANGE =>
                -- O valor do troco (vt_o) já está no credit_o do BO
                -- e é a última atualização que ocorreu no registrador de crédito.
                if unsigned(credit_i) > 0 then
                    nt_o <= '1'; -- Sinaliza necessidade de troco
                    load_credit_o <= '1';
                    sel_next_credit_o <= "10"; -- Zera o crédito
                else
                    nt_o <= '0';
                end if;
                next_state <= IDLE; -- Retorna a IDLE após lidar com o troco

        end case;
    end process;

end architecture fsm;
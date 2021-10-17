-------------------------------------------------------------------------------
--
-- INF3500 | laboratoire #3 | automne 2021
--
-- v. 1.1 2021-10-17 Pierre Langlois : intesection Chemin Côte Sainte-Catherine (CCSC) et Avenue Vincent D'Indy (AVDI)
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utilitaires_inf3500_pkg.all;
use work.all;

entity feux_circulation_tb is
    generic (
        DUREE_ROUGE_PARTOUT : positive := 3;               -- durée des feux rouges dans toutes les directions, en secondes
        DUREE_JAUNE : positive := 1;                       -- durée d'un feu jaune, en secondes
        DUREE_VERT : positive := 15;                       -- durée d'un feu vert, en secondes
        DUREE_PIETONS : positive := 10                     -- durée du feu pour les piétons, en secondes
    );
end feux_circulation_tb;

architecture arch_tb of feux_circulation_tb is

signal clk_1_Hz, reset : std_logic := '0';
signal activer : std_logic := '0';
signal bouton_appel_pieton : std_logic := '0';

signal feux_CCSC_est : std_logic_vector(5 downto 0);
signal feux_CCSC_ouest : std_logic_vector(7 downto 0);
signal feux_AVDI : std_logic_vector(5 downto 0);

signal decompte_pietons : BCD1;
signal decompte_pietons_allume : std_logic;

constant PERIODE : time := 1 sec;

begin

    clk_1_Hz <= not clk_1_Hz after PERIODE / 2;
    reset <= '1' after 0 sec, '0' after 7 * PERIODE / 4;
    activer <= '0' after 0 sec, '1' after 3 * PERIODE, '0' after 5 * PERIODE;
    
	-- instanciation du module à vérifier
    UUT : entity feux_circulation(arch)
        generic map (
            DUREE_ROUGE_PARTOUT => DUREE_ROUGE_PARTOUT,
            DUREE_JAUNE => DUREE_JAUNE,
            DUREE_VERT => DUREE_VERT,
            DUREE_PIETONS => DUREE_PIETONS
        )
        port map (
            clk_1_Hz => clk_1_Hz,
            reset => reset,
            activer => activer,
            bouton_appel_pieton => bouton_appel_pieton,
            feux_CCSC_est => feux_CCSC_est,
            feux_CCSC_ouest => feux_CCSC_ouest,
            feux_AVDI => feux_AVDI,
            decompte_pietons => decompte_pietons,
            decompte_pietons_allume => decompte_pietons_allume
        );

    -- vérifications de sécurité
    process(all)
    begin
        if rising_edge(clk_1_Hz) then
            
            -- pour voir la valeur des sorties, pour déboguage
--            report to_string(feux_CCSC_est) severity note;
--            report to_string(feux_CCSC_ouest) severity note;
--            report to_string(feux_AVDI) severity note;
            
            -- votre code ici, quelques exemples sont donnés
            assert nand(feux_CCSC_est(3), feux_AVDI(3)) report "feux verts dans deux directions en même temps, cas #1 !" severity failure;
            assert nand(feux_CCSC_ouest(3), feux_AVDI(3)) report "feux verts dans deux directions en même temps, cas #2  !" severity failure;
            assert nand(feux_CCSC_ouest(6), feux_AVDI(3)) report "feux verts dans deux directions en même temps, cas #3  !" severity failure;
            -- etc.
        end if;
        
    end process;
end arch_tb;
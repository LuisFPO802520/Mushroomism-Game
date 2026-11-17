# Objetos universais — floresta de cogumelos, versão 2

**Status: exportado e verificado.** Os dez PNGs passaram nas 92 verificações de dimensões, transparência, máscaras e recortes. A água tem dois quadros distintos; lodo e seiva têm quatro cada. A [prévia dos objetos](../../../_sprites_em_preparo/revisao_2026-11-11/previews/catalogo_universais_4x.png) mostra o resultado. [Relatório de conferência](../../../_sprites_em_preparo/revisao_2026-11-11/universais_validacao.txt).

A preparação adapta os dez arquivos de `sprites/Default/5 - Misc. universal tiles/` para a floresta de cogumelos. As formas menores usam a estrutura original, uma paleta temática e alterações pontuais; casas, conjunto utilitário e luz de resgate usam novas fontes geradas por IA e encaixadas no Photoshop. A montagem e as alterações são feitas por **rotina JSX nativa no Photoshop**, não por uma edição exclusivamente manual por cliques.

## Arquivos, dimensões e recortes

| Original de referência | Novo PNG | Dimensão e grade | Adaptação |
|---|---|---|---|
| `Blocks (16 x 16).png` | `blocos_micelio_16.png` | **176 × 96**; grade **11 × 6** de 16 × 16 | Preserva as formas e regiões do atlas; aplica paleta da floresta e pequenos grupos de musgo e micélio sobre peças ocupadas. |
| `Bubbling_Oil_frames (16 x 32).png` | `lodo_esporos_4_quadros_16x32.png` | **64 × 32**; quatro quadros **16 × 32**, em X0, 16, 32 e 48 | Mantém o desenho e o sombreamento dos quadros de óleo, com tons escuros violetas e reflexos frios. |
| `ChatGPT Image 1 de set. de 2026, 21_21_15.png` | `luz_resgate.png` | **1774 × 887**; imagem única, sem grade regular | Usa uma nova fonte de luz gerada por IA, normalizada ao canvas original, preservando alpha e brancos luminosos. |
| `Flowers (16 x 16).png` | `flores_fungicas_4_variantes_16.png` | **64 × 16**; quatro variantes estáticas **16 × 16**, em X0, 16, 32 e 48 | Redesenha as quatro flores como pequenos fungos com chapéu, caule e base de musgo, em cyan, violeta, coral e dourado. |
| `House (112 x 96).png` | `refugio_cogumelo_2_variantes_112x96.png` | **240 × 96**; casas nas regiões **(0, 0, 112, 96)** e **(128, 0, 112, 96)**; X112–127 transparente | Recorta uma fonte IA em duas casas-refúgio: porta fechada à esquerda e aberta à direita. Cada casa é ajustada à própria região e alinhada pela base. |
| `Lava_frames (16 x 32).png` | `seiva_fungica_4_quadros_16x32.png` | **64 × 32**; quatro quadros **16 × 32**, em X0, 16, 32 e 48 | Mantém as formas e os detalhes da lava, com paleta magenta e acentos claros. |
| `Metal_Wire_fence (16 x 16).png` | `cerca_raizes_micelio_16.png` | **224 × 48**; grade **14 × 3** de 16 × 16 | Preserva a malha, posições e encaixes da cerca original; recebe paleta verde/teal e pequenas folhas de dois pixels em módulos elegíveis. |
| `Rock_shape (16 x 16).png` | `pedra_fungica_16.png` | **16 × 16**; uma peça estática | Reutiliza a pedra temática anterior de `sprites/floresta_cogumelos/tiles/pedra_fungica_16.png`, quando presente; a rotina conserva o tamanho de 16 × 16. |
| `Snack_machine_Bench_Trash_bin (16 x 16).png` | `suprimentos_banco_cesto_16.png` | **128 × 64**; grade **8 × 4** de 16 × 16, com três objetos estáticos | Encaixa recortes de uma nova fonte IA: dispensador de esporos, banco de raízes e cesto de esporos. As regiões de destino são indicadas abaixo. |
| `Water_frames (16 x 32).png` | `agua_bioluminescente_2_quadros_16x32.png` | **32 × 32**; dois quadros **16 × 32**, em X0 e 16 | Preserva as formas, os reflexos e a diferença entre os quadros de água, em teal e cyan. |

Lodo, seiva e água usam quadros inteiros de **16 × 32**. A divisão visual em células 16 × 16 não transforma cada metade em um quadro independente. Os quatro fungos são variantes de decoração, não um ciclo de animação. As duas casas são estados diferentes de um refúgio.

## O que mudou no desenho

**Blocos:** a versão final mantém a ocupação dos pixels e os detalhes do original. A cor foi ajustada com matiz/saturação e filtro violeta no Photoshop, preservando as linhas de tijolo, madeira e metal. A camada de musgo e os detalhes de micélio ficam separados no PSD.

**Cerca:** a geometria da malha e os pontos de encontro dos módulos são preservados. A adaptação usa filtro verde/teal, preserva o sombreamento e acrescenta pequenas folhas em camada separada. A estrutura continua sendo uma cerca com malha, adequada para barreiras e limites do cenário.

**Flores:** a referência recolorida fica oculta no PSD, e uma nova camada desenha quatro fungos distintos em suas próprias células 16 × 16. Cada variante tem chapéu, haste clara, pequenos pontos e musgo na base. As silhuetas e cores variam para manter as quatro opções de decoração.

**Casas:** a fonte IA contém dois refúgios de chapéu violeta, madeira e luz cyan. A montagem separa a metade esquerda e a direita, remove margens transparentes, ajusta cada casa sem alterar sua proporção e a posiciona dentro de uma região 112 × 96. A faixa central de 16 pixels fica reservada à transparência. O PNG de exportação usa redução para 32 cores, sem dithering; o PSD conserva as camadas de montagem.

**Conjunto utilitário:** os três objetos são recortados individualmente da fonte IA e encaixados em um canvas transparente de 128 × 64. As coordenadas abaixo são as regiões de destino `(x, y, largura, altura)`, não uma promessa de preenchimento de todos os pixels dessas áreas:

| Objeto | Região de destino |
|---|---|
| Dispensador de esporos | **(20, 16, 24, 32)** |
| Banco de raízes / apoio utilitário | **(52, 31, 40, 17)** |
| Cesto de esporos | **(98, 33, 12, 15)** |

Os três objetos usam a mesma base na linha Y47. A montagem usa **Nearest Neighbor** nos recortes e uma cópia reduzida a 32 cores, sem dithering, para a exportação PNG. A fonte de três objetos não é aplicada como uma imagem inteira sobre o atlas.

**Luz de resgate:** é uma nova fonte IA inspirada na composição do efeito original: cone, halo superior e partículas em cyan/teal/lavanda. A rotina mantém o canvas de 1774 × 887 e preserva a luminosidade e o canal alpha da arte. Não remove branco dessa imagem, porque ele faz parte do brilho.

## Paleta e transparência

Os atlas menores preservam a máscara dos originais, com alpha binário. Na finalização, blocos, cerca e líquidos recebem ajustes contínuos de cor no Photoshop, para conservar texturas e diferenças entre quadros. O lodo usa tons escuros violetas; a seiva usa magenta; a água usa teal/cyan. As folhas da cerca e o musgo dos blocos permanecem em camadas separadas.

A paleta combina sombras azul-noturno, teal escuro, violeta, cyan, lavanda, musgo verde e madeira marrom. O contraste deve continuar sendo conferido sobre os fundos reais da fase.

Casas e conjunto utilitário usam fontes geradas com transparência; sua exportação passa por uma paleta de 32 cores com transparência e sem dithering. A luz é uma imagem de efeito com alpha preservado, portanto não deve ser tratada como uma máscara binária de colisão ou ter seus brancos luminosos apagados.

Nas casas e no mobiliário, a máscara de transparência foi recuperada do PSD e aplicada com limiar 128 após a redução de cores. Assim, os brancos luminosos que pertencem aos objetos são preservados e o fundo fica realmente transparente.

## Origem, prompts e editáveis

- **Referências de estrutura:** os dez arquivos originais em `sprites/Default/5 - Misc. universal tiles/`, listados na primeira tabela, fornecidos no projeto do aluno.
- **Pedra temática já existente:** `sprites/floresta_cogumelos/tiles/pedra_fungica_16.png`; a rotina a reutiliza em vez de sobrescrever o arquivo anterior.
- **Fontes novas de House, Snack e Light:** produzidas em 11/11/2026 com a ferramenta integrada `image_gen.imagegen`, usando os originais como referência de estrutura ou de composição. A geração e a adaptação tiveram assistência de IA (OpenAI/Codex).
- **Prompt das casas:** [`house_refugio_2_estados_prompt.txt`](../../../_sprites_em_preparo/revisao_2026-11-11/fontes/house_refugio_2_estados_prompt.txt).
- **Prompt do conjunto utilitário:** [`snack_machine_bench_trash_bin_prompt.txt`](../../../_sprites_em_preparo/revisao_2026-11-11/fontes/snack_machine_bench_trash_bin_prompt.txt).
- **Prompt da luz:** [`luz_resgate_prompt.txt`](../../../_sprites_em_preparo/revisao_2026-11-11/fontes/luz_resgate_prompt.txt).
- **Montagem e alterações de pixels:** rotina nativa [`montar_universais.jsx`](../../../_sprites_em_preparo/revisao_2026-11-11/montar_universais.jsx), executada no Photoshop sobre documentos novos ou cópias.
- **Finalização de cor e alpha:** [`corrigir_alpha_universais.jsx`](../../../_sprites_em_preparo/revisao_2026-11-11/corrigir_alpha_universais.jsx), também executada no Photoshop. Preserva a textura dos materiais e a máscara dos objetos.
- **PSDs com camadas:** `_sprites_em_preparo/revisao_2026-11-11/editaveis/utilityPSD/`, separados dos PNGs consumidos pelo jogo.

Este guia foi preparado com ajuda de IA (OpenAI/Codex). As fontes originais e os arquivos anteriores são referências preservadas; a versão 2 tem sua própria pasta de saída.

## Montagem na Godot

Esta preparação fornece imagens. Lodo e seiva não passam a causar dano por receberem esses nomes; água não ativa nado, a luz não registra resgate, uma porta desenhada aberta não muda de fase e a cerca não ganha colisão automaticamente.

A arte foi conferida separadamente. A montagem no TileSet, as colisões e a reprodução dentro do jogo ficam para sua próxima etapa manual. Esta pasta contém as novas imagens; as referências anteriores permanecem em suas pastas originais.

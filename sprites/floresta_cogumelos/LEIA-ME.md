# Arte da floresta de cogumelos

Pacote de arte preparado com acabamento manual no Photoshop. As cenas, os mapas e os scripts do jogo não foram alterados nesta etapa. Colisões, obstáculos funcionais e comportamento dos esporos serão configurados depois.

## Fundos com parallax

As cinco imagens da pasta `parallax` têm **288 × 208 pixels**, a mesma área do viewport atual. A imagem 5 é o fundo opaco; as demais têm transparência para aparecerem sobre ela.

| Nó da camada, de trás para frente | Arquivo a usar no Sprite2D → Texture |
|---|---|
| `ParallaxBackground/5` | `parallax/5_nevoa_fundo.png` |
| `ParallaxBackground/4` | `parallax/4_floresta_distante.png` |
| `ParallaxBackground/3` | `parallax/3_arvores_intermediarias.png` |
| `ParallaxBackground/2` | `parallax/2_cogumelos_luminosos.png` |
| `ParallaxBackground/1` | `parallax/1_vegetacao_proxima.png` |

Quando formos montar a arte no editor, esse mapeamento se aplica às cinco camadas existentes de `scene/map1.tscn`: trocar somente **Texture** do Sprite2D de cada camada. Preservar as posições, escalas e offsets existentes, **Centered desativado**, **Region Enabled ativado**, região **(0, 0, 576, 208)**, repetição da textura e **Motion Mirroring (288, 0)**.

Os valores atuais de **Motion Scale** em map1 são: camada 5 **(0.1, -0.1)**, 4 **(0.2, 0.2)**, 3 **(0.3, 0.3)**, 2 **(0.4, 0.4)** e 1 com o padrão **(1, 1)**. Não é necessário mudá-los para experimentar estas imagens.

`map_secret.tscn` só possui imagens nas camadas 5, 4 e 3; as camadas 2 e 1 estão vazias. `map2.tscn` possui seis camadas e outro arranjo de imagens, então precisa de um mapeamento próprio quando chegarmos a ele.

Use filtro de textura **Nearest / Vizinho mais próximo** para preservar os pixels; o projeto atual já usa esse filtro. Confira a emenda horizontal ao testar o parallax: ela ainda não foi validada como perfeita.

## Terreno, decoração e efeito

| Arquivo na pasta `tiles` | Dimensão e uso |
|---|---|
| `terreno_musgo_violeta_16.png` | **272 × 160**, grade **16 × 16**. Mesmas posições e formas do atlas de terreno original, com solo azul escuro e musgo violeta. |
| `cogumelos_decorativos_16.png` | **288 × 128**, dois grupos decorativos grandes lado a lado: cyan à esquerda e violeta à direita. |
| `esporos_ciano_5_quadros_32.png` | **160 × 32**, cinco quadros horizontais de **32 × 32**, partículas cyan `#65F8ED`. É somente o visual do efeito. |
| `pedra_fungica_16.png` | **16 × 16**: pedra azul com três pixels cyan luminosos. Arquivo exportado com transparência. |

O nome `cogumelos_decorativos_16.png` indica a grade, não o tamanho de cada cogumelo. **Cada grupo ocupa 9 × 8 células de 16 pixels, ou 144 × 128 pixels.** As regiões são:

- Grupo esquerdo: **Rect2(0, 0, 144, 128)**.
- Grupo direito: **Rect2(144, 0, 144, 128)**.

Ao criar o TileSet, cada grupo deve ser tratado como uma peça grande de **9 × 8 células**, ou usado como Sprite2D. Selecionar uma única célula 16 × 16 recortaria apenas um pedaço da decoração. O arquivo veio de um recorte da camada 2, removendo os 80 pixels superiores; não é um atlas de cogumelos pequenos independentes.

O terreno mantém a organização original para facilitar o uso das regiões já conhecidas. A aparência do chão e sua colisão são recursos separados: uma imagem nova, por si só, não cria nem modifica colisões.

## Prévia e arquivo editável

- `previews/floresta_5_camadas.png`: composição das cinco camadas em 288 × 208, apenas para visualizar o resultado. No Godot, use os cinco PNGs separados da pasta `parallax`.
- `previews/floresta_5_camadas.psd`: montagem editável salva no Photoshop. De cima para baixo: Camada 4 = vegetação próxima; Camada 3 = cogumelos luminosos; Camada 2 = árvores intermediárias; Camada 1 = floresta distante; Plano de Fundo = névoa.

## Fontes e edição

Os fundos foram reconstruídos a partir da arte plana de floresta já disponível nesta conversa, com fontes geradas por IA e acabamento no Photoshop. **Não são camadas originais recuperadas da imagem achatada.** A referência principal foi `_arquivo_assistente_2026-10-28/docs/arte_planejada/floresta_estudo_background.png`; os arquivos de trabalho ficam em `_arte_floresta_fontes`.

Terreno, pedra e esporos são adaptações dos recursos que já existiam no pacote `Default` do projeto:

- Terreno: `sprites/Default/1 - Grassland/Terrain (16 x 16).png`. Recoloração no Photoshop: Matiz **−157**, Saturação **−19**, Luminosidade **−21**, preservando as posições do atlas.
- Pedra: `sprites/Default/5 - Misc. universal tiles/Rock_shape (16 x 16).png`. Recoloração no Photoshop com **Colorize / Colorir**: Matiz **208**, Saturação **25**, Luminosidade **−21**, com três pixels cyan `#65F8ED` acrescentados sobre a pedra.
- Esporos: `sprites/Default/2 - Fairy/Magic_Sparkle_Trail (32 x 32).png`, recolorido para cyan.

Essas fontes usam PNG RGB com branco definido como transparente por chave de cor. No acabamento, esse branco foi convertido em transparência de canal alpha. Os arquivos exportados de terreno, pedra e esporos preservam a área visível da fonte; o fundo 5 continua opaco por intenção.

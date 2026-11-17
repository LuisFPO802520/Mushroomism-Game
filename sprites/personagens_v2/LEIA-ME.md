# Personagens v2 — animações em 32 × 32

**Status: exportado e verificado.** Foram conferidos os 216 quadros, as dimensões, a transparência e a correspondência entre faixas e folhas. As 78 comparações da cabeça nas poses normais e as 24 comparações nas poses deitadas passaram. A reprodução dentro da Godot ainda depende da sua montagem manual. [Relatório completo](../../_sprites_em_preparo/revisao_2026-11-11/personagens_verificacao.txt).

O pacote contém Mush, Ruby, Moss, Nox, Pingo e Luma. Cada personagem tem quadros de **32 × 32 pixels**, fundo transparente e os mesmos **16 estados** do conjunto de referência em `sprites/Default/1 - Penguin`. As 16 faixas somam **36 quadros por personagem**.

## Onde está cada arquivo

- Na raiz de `sprites/personagens_v2/`: as folhas de compatibilidade `<nome>_32.png` e os atlas gerais `<nome>_atlas_32.png`. Os nomes são `mush`, `ruby`, `moss`, `nox`, `pingo` e `luma`. Exemplo: `sprites/personagens_v2/mush_atlas_32.png`.
- Em uma pasta por personagem, como `mush/` e `ruby/`: as 16 faixas individuais, com nomes como `Idle (32 x 32).png`, e `base_cabeca_32.png`.
- `base_cabeca_32.png` é uma **referência de desenho**, não uma animação nem um quadro adicional na contagem de 36. Registra a cabeça limpa reutilizada na montagem das poses.
- Os PSDs de trabalho ficam em `_sprites_em_preparo/revisao_2026-11-11/editaveis/`, separados dos PNGs do jogo. Essa pasta de trabalho deve permanecer excluída da importação da Godot; os PSDs não devem ser usados como recursos nas cenas.

## Faixas individuais e atlas geral

Cada faixa tem **uma única linha de 32 pixels de altura**. A largura é a quantidade de quadros multiplicada por 32. Os nomes dos estados mantêm a grafia da referência do pinguim.

O atlas geral de cada personagem tem **192 × 512 pixels**: **6 colunas × 16 linhas** de células 32 × 32. A ordem das linhas é alfabética, como na tabela. Cada linha começa na primeira coluna e usa somente a quantidade indicada; as células restantes ficam totalmente transparentes. São 36 quadros ocupados e 60 células vazias por atlas.

| Linha do atlas | Estado da referência | Quadros exatos | Tamanho da faixa | Pose |
|---:|---|---:|---|---|
| 1 | `Belly_Sliding` | 3 | 96 × 32 | Deslizar com o corpo baixo e a cabeça preservada |
| 2 | `Blink` | 1 | 32 × 32 | Pose neutra com olhos fechados |
| 3 | `Ducking` | 1 | 32 × 32 | Agachar dobrando o corpo e as pernas |
| 4 | `Falling` | 1 | 32 × 32 | Pose fixa de queda |
| 5 | `Hurt` | 1 | 32 × 32 | Reação curta de dano |
| 6 | `Idle` | 5 | 160 × 32 | Respiração discreta em repouso |
| 7 | `Jump` | 1 | 32 × 32 | Pose fixa de subida no pulo |
| 8 | `Looking_Off` | 1 | 32 × 32 | Olhar para longe, com vista de costas redesenhada |
| 9 | `Looking_Up` | 2 | 64 × 32 | Olhar normal e olhar para cima |
| 10 | `Lying_On_Ground` | 1 | 32 × 32 | Corpo deitado, mantendo a identidade da cabeça |
| 11 | `Sitting` | 2 | 64 × 32 | Sentar e descansar |
| 12 | `Standing` | 1 | 32 × 32 | Pose neutra de referência |
| 13 | `Surprised` | 1 | 32 × 32 | Reação de surpresa |
| 14 | `Swimming` | 4 | 128 × 32 | Movimento alternado de braços e pés |
| 15 | `Victory_Dance` | 5 | 160 × 32 | Comemoração com pequenos movimentos |
| 16 | `Waddling` | 6 | 192 × 32 | Ciclo de caminhada |

## Folha de compatibilidade 128 × 96

Os arquivos `<nome>_32.png` da raiz mantêm a organização da primeira versão: **128 × 96 pixels**, **4 colunas × 3 linhas**, com 12 células de 32 × 32. Use essas folhas para aproveitar os recortes atuais. As faixas individuais oferecem os ciclos completos, incluindo seis quadros na caminhada.

| Linha | Nome de animação na Godot | Conteúdo |
|---|---|---|
| 1 | `idle` | Quatro quadros selecionados do estado `Idle` |
| 2 | `walk` | Quatro quadros selecionados do ciclo `Waddling` |
| 3 | `jump` | A mesma pose fixa de `Jump` repetida nos quatro quadros |

A repetição da pose de `Jump` é intencional: tocar a animação não deve fazer o desenho subir e descer dentro do quadro enquanto a física já move o personagem. Essa folha serve para conservar o recorte 4 × 3 existente; não contém todos os 16 estados.

## Consistência visual

- Preservar chapéu e rosto como uma unidade rígida, sem esticar, comprimir ou deformar a face para simular movimento.
- Desenhar mudanças pontuais de expressão, como fechar os olhos, mantendo proporções, cores e identidade de cada personagem.
- Nas poses apoiadas, manter uma base e um centro de referência consistentes. Mover braços, pernas e corpo sem fazer os pés oscilarem pela folha.
- Os 114 PNGs deste pacote usam alpha **binário**: somente 0, totalmente transparente, ou 255, totalmente opaco. Esse total inclui as seis referências de cabeça e as doze folhas.
- Manter pixels nítidos e evitar suavização nas transformações e exportações.

## Integração posterior pela interface da Godot

A [prévia local — Laboratório de animações](../../_sprites_em_preparo/revisao_2026-11-11/previa.html) permite comparar os seis personagens, selecionar os 16 estados, pausar, avançar quadros e ajustar FPS, ampliação e fundo. Abra o arquivo HTML no navegador. A prévia informa arquivos indisponíveis ou dimensões incorretas; isso não substitui a conferência final na Godot.

Esta revisão preparou e conferiu as imagens. A versão atual de `scene/map2.tscn` já referencia as faixas `Idle`, `Waddling`, `Jump` e `Ducking` do Mush; essa montagem foi preservada. A edição de imagens não configura automaticamente os demais estados ou personagens, e a reprodução no jogo não foi testada nesta revisão.

Na montagem manual do `AnimatedSprite2D`, recortar sempre células de **32 × 32**. Para a folha de compatibilidade, usar **Horizontal = 4** e **Vertical = 3**. Para o atlas geral, usar **Horizontal = 6** e **Vertical = 16**, selecionando apenas as células ocupadas de cada linha. Nas faixas individuais, usar a quantidade de colunas da tabela e **Vertical = 1**.

O estado `Ducking` fornece a pose para a animação chamada **`duck`** na Godot, compatível com o nome que o script atual utiliza. `Waddling` corresponde a **`walk`**; `Idle` a **`idle`**; `Jump` a **`jump`**. Os demais nomes só terão efeito quando forem configurados e usados pelo comportamento do jogo.

Em uma integração futura, podemos separar `Jump` e `Falling`, cada um com **um único quadro**: mostrar a pose de subida quando a velocidade vertical for negativa e a pose de queda quando for positiva. A troca deverá acompanhar a física, sem deslocamento artificial do desenho dentro da célula.

**Não há animação de ataque neste pacote.** Os 16 estados seguem a referência do pinguim; ataque e outras ações do jogo exigirão uma etapa própria.

## Origem e conclusão da preparação

As imagens-base dos seis personagens foram geradas com a ferramenta integrada `image_gen.imagegen` em **28/10/2026**, a partir das descrições do aluno. Nesta revisão, uma cabeça de cada personagem foi limpa e reutilizada nas poses; não foram geradas novas cabeças para cada estado.

A montagem dos atlas, faixas e folhas de compatibilidade, a limpeza de paleta e as alterações pontuais de corpo e expressão foram feitas por **rotinas JSX nativas no Photoshop**, com assistência de IA (OpenAI/Codex). A cabeça é reutilizada sem escala ou distorção; as poses deitadas usam giro exato de 90 graus em canvas 32 × 32. As rotinas trabalham em documentos novos e exportam os PNGs da versão 2; não programam o comportamento dos personagens na Godot.

Rotina de montagem: [`montar_personagens.jsx`](../../_sprites_em_preparo/revisao_2026-11-11/montar_personagens.jsx). PSDs, leituras das bases e demais arquivos de trabalho ficam em `_sprites_em_preparo/revisao_2026-11-11/`; os registros da geração original permanecem em `_sprites_em_preparo/fontes/`. Este guia foi preparado com ajuda de IA (OpenAI/Codex).

A finalização e os retoques de contorno estão em [`finalizar_previas.jsx`](../../_sprites_em_preparo/revisao_2026-11-11/finalizar_previas.jsx). A [comparação visual dos seis personagens](../../_sprites_em_preparo/revisao_2026-11-11/previews/catalogo_personagens_4x.png) mostra seis poses de cada um. Os originais anteriores foram mantidos; esta pasta contém os novos arquivos para sua escolha na Godot. Ao trocar as texturas, confira o alinhamento do desenho com o colisor que você já configurou.

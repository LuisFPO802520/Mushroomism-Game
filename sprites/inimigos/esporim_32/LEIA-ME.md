# Esporim — folhas de animação 32 × 32

**Status: exportado e verificado.** As sete faixas, os 24 quadros, o atlas e a transparência passaram na validação. As 18 comparações da cabeça nas poses normais coincidiram com a base, considerando os deslocamentos do manifesto. A reprodução dentro da Godot não foi testada nesta entrega. [Relatório completo](../../../_sprites_em_preparo/combate_2026-11-16/combate_verificacao.txt).

Esporim é o inimigo comum de esporos da floresta. Seu ataque é um **golpe de raízes/garras curtas**, sem galho. Este pacote contém **7 estados e 24 quadros**, com fundo transparente e **32 × 32 pixels por quadro**.

| Arquivo | Nome na Godot | Quadros | Dimensão da faixa | FPS inicial | Repetir na Godot |
|---|---|---:|---|---:|---|
| `Idle (32 x 32).png` | `idle` | 4 | 128 × 32 | 5 | Sim |
| `Run (32 x 32).png` | `run` | 6 | 192 × 32 | 8 | Sim |
| `Jump (32 x 32).png` | `jump` | 1 | 32 × 32 | 1 | Pose fixa |
| `Falling (32 x 32).png` | `fall` | 1 | 32 × 32 | 1 | Pose fixa |
| `Attack (32 x 32).png` | `attack` | 6 | 192 × 32 | 12 | **Não** |
| `Hurt (32 x 32).png` | `hurt` | 2 | 64 × 32 | 8 | **Não** |
| `Death (32 x 32).png` | `death` | 4 | 128 × 32 | 8 | **Não** |

## Montagem posterior na Godot

Também está disponível **`esporim_atlas_32.png`**, com **192 × 224 pixels**, seis colunas e sete linhas, na mesma ordem da tabela. Use apenas os quadros indicados em cada linha: as 18 células restantes são transparentes. `base_cabeca_32.png` é referência de desenho, não uma animação adicional.

No `AnimatedSprite2D`, adicionar os quadros de cada faixa usando **Horizontal = quantidade de quadros da tabela** e **Vertical = 1**. Cada recorte deve ter exatamente **32 × 32**. Usar os nomes de animação em letras minúsculas indicados na tabela; o arquivo `Falling` corresponde ao nome **`fall`**.

A animação **`run`** será reutilizada tanto na patrulha quanto na perseguição. A velocidade de deslocamento poderá mudar conforme o comportamento; não é necessário criar outra folha para correr atrás do jogador. Para olhar para a esquerda, usar **Flip H / `flip_h`**, mantendo a mesma sequência de imagens.

`jump` e `fall` são poses únicas para acompanhar, respectivamente, a subida e a queda. `attack`, `hurt` e `death` devem ficar **sem repetição**. O retorno a outro estado e a permanência no último quadro da morte serão definidos na lógica do inimigo, em uma etapa de integração.

## Quadros de ataque

A referência visual de impacto do Esporim está nos quadros **3 e 4**, contando a partir de 1. Na indexação que começa em zero, correspondem aos índices **2 e 3**. Esses quadros mostram a extensão das garras; não criam hitbox, dano ou colisão automaticamente.

O ataque do Mush possui outra sequência, com **8 quadros** e referência visual de impacto nos quadros **4 e 5**, também contando a partir de 1. As marcações de arte servem para orientar a integração posterior.

## Prévia local

Abra a [prévia de combate — Mush e Esporim](../../../_sprites_em_preparo/combate_2026-11-16/previa_combate.html) no navegador. Ela permite selecionar o estado do inimigo, ajustar FPS, ampliar em 4× ou 6×, pausar e avançar os quadros. Arquivos indisponíveis ou dimensões incorretas aparecem nos cartões.

**Só arte:** a prévia não demonstra hitbox nem dano real. Os ciclos repetem na página para facilitar a inspeção; isso não substitui a configuração sem repetição de `attack`, `hurt` e `death` dentro da Godot.

## Fontes, editáveis e conferência

O desenho-base do Esporim foi criado com a ferramenta integrada `image_gen.imagegen`, com assistência de IA (OpenAI/Codex). O [prompt utilizado](../../../_sprites_em_preparo/combate_2026-11-16/fontes/esporim_prompt.txt) e a fonte ficam em `fontes/`. A montagem em 32 × 32, a paleta e as animações foram finalizadas no Photoshop por [rotina JSX nativa](../../../_sprites_em_preparo/combate_2026-11-16/montar_combate.jsx). Uma mesma cabeça limpa é reutilizada, preservando os olhos e as proporções.

Os PSDs com camadas ficam em `_sprites_em_preparo/combate_2026-11-16/editaveis/`: `esporim_animacoes_32.psd` e `mush_attack_32.psd`. O [catálogo de combate](../../../_sprites_em_preparo/combate_2026-11-16/previews/catalogo_combate.png) mostra todos os quadros. Os arquivos de trabalho permanecem separados dos PNGs consumidos pelo jogo.

Esta entrega prepara a arte. Na leitura do projeto em 16/11/2026, o protótipo em `script/enemy/character_body_2d.tscn` tinha animações vazias, `AnimatedSprite2D` oculto e ainda não possuía código de IA/combate. Essas configurações foram preservadas para a etapa manual: será necessário cadastrar os quadros, tornar o sprite visível, configurar colisões e ligar os estados à lógica de perseguição, pulo e dano.

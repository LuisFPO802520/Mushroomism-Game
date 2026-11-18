# Ataque do Mush — galho

Arquivo: **`Attack (32 x 32).png`**, uma faixa de **256 × 32 pixels**, com **8 quadros de 32 × 32**.

Use uma animação chamada **`attack`**, com **16 FPS** e **sem repetir**. O ciclo dura aproximadamente meio segundo. O oitavo quadro volta à pose `Standing`, facilitando o retorno ao repouso.

| Quadro | Movimento |
|---:|---|
| 1 | Leva o galho para trás do corpo e do chapéu |
| 2 | Levanta a arma junto ao chapéu |
| 3 | Acelera o galho para a frente; começa um rastro discreto |
| **4** | **Contato diagonal frontal** |
| **5** | **Extensão horizontal e impacto** |
| 6 | Continua o golpe para baixo; o rastro se desfaz |
| 7 | Recolhe a arma |
| 8 | Retorna à pose neutra original |

A cabeça e o rosto são os mesmos do Mush atual. Os pés permanecem na base da célula e o movimento principal fica no braço e no galho. O rastro ciano já está desenhado nos quadros; não é necessário criar um nó de efeito para vê-lo.

Para importar a faixa, use **8 colunas e 1 linha**. Para a esquerda, use o mesmo `flip_h` que o personagem já utiliza. Os quadros 4 e 5 são uma referência visual para ativar a área de acerto quando a lógica de combate for montada.

Esta entrega acrescenta a animação. O script atual do jogador ainda precisa disparar `attack` e tratar tecla, área de acerto e dano; esses comportamentos não são produzidos pelo PNG.

Na leitura do projeto em 16/11/2026, o mapa principal instancia `utils/mush.tscn`; `map2.tscn` mantém um personagem com `SpriteFrames` embutido independente. Cadastre a nova animação no personagem usado em cada cena que você quiser testar.

[Prévia de combate](../../../_sprites_em_preparo/combate_2026-11-16/previa_combate.html) · [Folha ampliada](../../../_sprites_em_preparo/combate_2026-11-16/previews/mush_attack_6x.png)

O PSD com camadas está em `_sprites_em_preparo/combate_2026-11-16/editaveis/mush_attack_32.psd`. A montagem foi feita no Photoshop por rotina JSX nativa, reutilizando as imagens atuais e sem regenerar o rosto por IA. A fonte do inimigo foi criada separadamente com a ferramenta integrada `image_gen.imagegen`.

**Status: exportado e verificado.** Os oito quadros são distintos; a cabeça coincide com a referência nos oito quadros; o último quadro coincide integralmente com `Standing`. PNG RGBA de 8 bits, transparência binária e margens conferidas. [Relatório da validação](../../../_sprites_em_preparo/combate_2026-11-16/combate_verificacao.txt).

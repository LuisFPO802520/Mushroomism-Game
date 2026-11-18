# Mush e resgate de aliados

Os scripts já estão ligados às cenas. O desenho e as posições dos mapas não foram alterados.

## Jogar

- A/D ou setas: andar.
- Espaço, W ou seta para cima: pular; apertar novamente no ar faz o segundo salto.
- S ou seta para baixo: agachar no chão.
- **J: atacar com o galho.** O golpe também funciona no ar.
- Encostar em um aliado parado: resgatá-lo. Ele entra na fila pela ordem do resgate.

## Vida e dano do Mush

`script/player.gd` começa com **5 pontos de vida** e **1 de dano por golpe**. Selecione a raiz do Mush e altere `Max Health` ou `Attack Damage` no Inspetor para ajustar esses valores.

Ao receber dano, Mush toca `hurt`, recua e pisca durante 1 segundo de invulnerabilidade. Ao zerar a vida, os controles são bloqueados e a tela de Game Over aparece após 1 segundo. Ainda não existe `death` no SpriteFrames do Mush: nesse caso ele usa `hurt` antes de mostrar o menu. O canto superior mostra a vida e os aliados resgatados.

O script usa as animações já cadastradas: `idle`, `walk`, `jump`, `duck`, `attack` e `hurt`. A queda usa a tira `Falling`. As cópias antigas do jogador em outros mapas também recebem os estados novos em execução. `attack` e `hurt` têm o loop desligado em execução, preservando os recursos originais.

O galho acerta à frente nos quadros **4 e 5** da animação de oito quadros (índices 3 e 4). Cada inimigo recebe no máximo um dano por golpe, mesmo permanecendo dentro do alcance.

Para um inimigo ou perigo causar dano:

```gdscript
player.take_damage(1, global_position)
```

Para curar:

```gdscript
player.heal(1)
```

`health` contém a vida atual. Os sinais `health_changed(current_health, maximum_health)`, `damaged(amount)` e `died` ficam disponíveis para ligar sons e efeitos. `GameSession` já usa o primeiro sinal para atualizar a vida na tela e manter o valor entre mapas.

## Aliados

As cinco cenas prontas estão em `utils`: `ruby.tscn`, `moss.tscn`, `nox.tscn`, `pingo.tscn` e `luma.tscn`. Moss e Luma continuam onde você os colocou; os outros três podem ser arrastados para o mapa manualmente.

Todas usam `script/ally.gd`. O aliado permanece exatamente no local em que foi colocado, tocando `idle`, até Mush encostar. O sensor é criado pelo script usando o `CollisionShape2D` existente. Nenhum aliado lê o teclado.

Depois do contato, ele segue o caminho horizontal de Mush e mantém até cinco aliados em fila, com 28 pixels de espaçamento. `Ally Spacing`, no Mush, altera esse valor. A altura do salto não consome o espaço da fila. Os corpos dos aliados colidem com o terreno, mas não empurram o jogador nem acionam as saídas.

O ingresso é gradual: o aliado aguarda espaço e entra pelo ponto do contato. Cada aliado agora pula com impulso, gravidade e pouso próprios, em vez de copiar a altura do jogador por posição. O pulo duplo mantém o intervalo dos dois impulsos de Mush.

No salto parado, cada aliado permanece no seu lugar da fila e pula com um pequeno atraso; `Jump Stagger`, na raiz da cena do aliado, ajusta esse intervalo (padrão: 0,06 segundo por posição). Correndo, os aliados procuram o mesmo ponto de decolagem. Em buracos e plataformas de outra altura, terminam a travessia em velocidade normal e aguardam em chão seguro; se o local for estreito, a fila se aproxima temporariamente e volta a abrir quando Mush anda.

O sinal `ally_rescued(ally, total)` informa cada resgate. O grupo `rescued_allies` identifica quem já entrou na fila. **Moss e os demais aliados agora acompanham as saídas para os próximos mapas.** O Autoload `GameSession`, em `script/game_session.gd`, mantém a vida restante e a lista de aliados enquanto o jogo está aberto. Ao retornar a um mapa, o personagem já resgatado não aparece duplicado em seu local antigo. Não há gravação de partida em disco.

## Interface em pixels

O HUD editável está em `ui/hud.tscn`, com o script `script/hud.gd`. Ele usa **cinco cabeças do Mush** para representar a vida: cada vida perdida apaga uma cabeça, e curar acende as cabeças novamente. Ao lado fica a cabeça do Moss com o contador `0/5`, que aumenta a cada resgate e continua correto ao trocar de mapa.

O HUD e o Game Over usam a fonte bitmap original `ui/fonts/floresta_pixel.fnt`, desenhada em uma grade 5×7 com números e acentos portugueses. Os tamanhos 8 e 16 preservam os pixels inteiros. As janelas e os botões do Game Over têm cantos quadrados e detalhes feitos de pequenos quadrados. Os arquivos originais dos sprites não foram alterados: as cabeças são recortadas por recursos `AtlasTexture` na cena do HUD.

## Quedas e Game Over

Cada queda na água ou lava desconta **1 ponto de vida**. Com cinco pontos e sem outros danos, a quinta queda causa Game Over. O dano de inimigos usa a mesma vida: se Mush já estiver ferido, pode morrer antes da quinta queda.

Os tiles de água e lava já pintados no mapa são reconhecidos pelo script. As áreas `Fall` existentes continuam como proteção no fundo dos mapas e não recarregam mais a fase. Uma mesma queda é cobrada apenas uma vez, mesmo que mais de um sensor seja acionado. A proteção temporária contra golpes não anula uma queda nova.

Nas primeiras quatro quedas, Mush volta ao último chão firme com apoio para os pés. Os aliados são recuperados junto dele e a fila se abre novamente ao andar. A fase continua na mesma instância, preservando os resgates e a vida restante.

Para criar outra área de perigo manualmente, use uma `Area2D` com `CollisionShape2D`, máscara de física 2 e `script/level_end.gd`. Marque `Is Hazard` e conecte `body_entered` ao método `_on_body_entered`. Para uma saída normal, mantenha `Is Hazard` desmarcado e informe `Next Level`.

A tela editável está em `ui/game_over.tscn`, com o script `script/game_over.gd`. Usa os fundos e sprites existentes da floresta, sem substituir a arte do mapa.

- **Tentar novamente:** recarrega a fase atual com a vida cheia e os aliados que já acompanhavam Mush na entrada dessa fase. Os resgates novos feitos na tentativa perdida voltam aos seus lugares.
- **Recomeçar jornada:** volta ao primeiro mapa com vida cheia e todos os aliados esperando para serem resgatados.

## Alvo para testar o golpe

`utils/enemy.tscn` agora usa `script/enemy.gd`: 3 pontos de vida, 1 de dano por contato e animações de dano/morte. Pode arrastá-lo para onde desejar testar. Nesta etapa ele fica parado com gravidade; patrulha, perseguição e ataques próprios ainda não foram programados.

Novos inimigos devem usar o grupo `enemies`, a camada de física 3 (valor 4) e implementar `take_damage(amount, source_position)`. Mush usa a camada de física 2 (valor 2); terreno usa a camada 1. Aliados usam apenas um sensor que detecta Mush.

## Arquivos de apoio

- Backup anterior às alterações: `_sprites_em_preparo/scripts_backup_2026-11-18/`.
- Teste de integração: `_sprites_em_preparo/testes_scripts_2026-11-18.gd`.
- Validação em 18/11/2026: 139 verificações passaram na Godot 4.7.2, incluindo os cinco aliados seguindo, saltando e pousando. Log: `_sprites_em_preparo/testes_integracao_2026-11-18.log`.
- Etapa de transições e perigos: `_sprites_em_preparo/testes_transicao_quedas_2026-11-18.gd`; log final em `_sprites_em_preparo/testes_transicao_quedas_final_2026-11-18.log`. O teste atravessa as saídas reais, volta ao mapa anterior, cai cinco vezes, usa os botões de Game Over e testa os tiles existentes de água e lava.
- Backup desta etapa: `_sprites_em_preparo/backup_transicao_quedas_2026-11-18/`.
- Correção dos saltos: `_sprites_em_preparo/testes_pulos_naturais_2026-11-18.gd`; validação final de 35 verificações de salto, mais 139 de combate/aliados e 105 de transições/perigos, todas aprovadas. Backup anterior à correção: `_sprites_em_preparo/backup_pulos_naturais_2026-11-18/`.
- Referências da API: [AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html), [PhysicsShapeQueryParameters2D](https://docs.godotengine.org/en/stable/classes/class_physicsshapequeryparameters2d.html).

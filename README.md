# bmc-operacao

Repositório de operação da TI da BMC Hyundai. Ele diz **o que está aprovado
para produção** e guarda a cópia de referência do que roda nas VMs.

| Pasta | O que é | Quem aprova mudança |
|---|---|---|
| `servicos/<serviço>/producao.env` | digest aprovado para produção (estado desejado) | dono do portal ou TI |
| `vm/` | `bmc-publicador`, configs, compose, systemd: **cópia de referência**. A VM usa a cópia instalada pela TI, não esta | TI |
| `.github/` | check `valida` e CODEOWNERS | TI |

## Como uma publicação acontece

1. Merge na `main` do repo do portal → o CI publica a imagem e move a tag
   `homologacao` → a homologação atualiza sozinha.
2. O bot `bmc-promotor` abre (ou atualiza) o PR `promover/<serviço>` aqui,
   trocando o `IMAGEM=` do `producao.env`.
3. O check `valida` confere formato, existência da imagem e commit de origem.
4. O dono testa a homologação, marca o checklist e **aprova**; merge.
5. Em até ~2 min o `bmc-publicador` da BMC-AGENT-01 aplica, confere o
   health e grava o status `publicacao/<serviço>` no commit do merge (verde
   = publicado; vermelho = falhou e voltou à versão anterior).

## Na VM (TI)

```bash
bmc-publicador status          # o que está rodando
bmc-publicador historico 20    # últimas publicações
bmc-publicador reverter <id>   # emergência: volta ao anterior e pausa
bmc-publicador retomar <id>    # depois do PR de reversão aqui
```

Registro: `/var/log/bmc-publicador/publicacoes.jsonl`. Métricas:
`bmc_publicacao_*` no Pushgateway da TICWay (Grafana org 21).

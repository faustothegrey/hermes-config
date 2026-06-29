# Faro — Installazione peer

## peer105 (Fedora 30 ARM, root SSH)

```bash
mkdir -p /root/.hermes/scripts
scp beacon.sh root@192.168.178.105:/root/.hermes/scripts/beacon.sh
ssh root@192.168.178.105 \
  "(crontab -l 2>/dev/null; echo '@reboot /root/.hermes/scripts/beacon.sh peer105 once') | crontab -"
```

## peer106 (Fedora 30 ARM, root SSH)

```bash
ssh root@192.168.178.106 "mkdir -p /root/.hermes/scripts"
scp beacon.sh root@192.168.178.106:/root/.hermes/scripts/beacon.sh
ssh root@192.168.178.106 \
  "(crontab -l 2>/dev/null; echo '@reboot /root/.hermes/scripts/beacon.sh peer106 once') | crontab -"
```

## peer128 (macOS 26, fausto SSH)

```bash
ssh fausto@192.168.178.128 "mkdir -p ~/.hermes/scripts"
scp beacon-macos.sh fausto@192.168.178.128:~/.hermes/scripts/beacon.sh
ssh fausto@192.168.178.128 \
  "(crontab -l 2>/dev/null; echo '*/2 * * * * ~/.hermes/scripts/beacon.sh') | crontab -"
```

## peer70 (Raspberry Pi, Debian 11 bullseye, aarch64)

**Tipo:** Sempre acceso full Hermes gateway. Nessun beacon.sh necessario.

```bash
# Dettagli di connessione
IP=192.168.178.70
USER=fausto

# 1. Verifica SSH e Hermes
ssh $USER@$IP "uname -a && free -h && df -h /"
ssh $USER@$IP "export PATH=\$PATH:/home/$USER/.local/bin && hermes --version"

# 2. Verifica gateway attivo
ssh $USER@$IP "cat ~/.hermes/gateway_state.json | grep gateway_state"

# 3. Se si vuole api_server per peer mesh:
#    Aggiungere a config.yaml su peer70:
#      api_server:
#        enabled: true
#        host: 0.0.0.0
#        port: 8642
#
#    Creare ~/.hermes/.env:
#      API_SERVER_KEY=<chiave>
#      API_SERVER_HOST=0.0.0.0
#
#    Riavviare gateway

# 4. Aggiungere a peer-mesh.yaml su N56VV:
#    peer70:
#      url: http://192.168.178.70:8642
#      api_key_env: HERMES_PEER_70_KEY
#      role: worker
#      capabilities:
#        - hermes
#        - lan
#      timeout: 300

# 5. Config variabile d'ambiente su N56VV:
#    HERMES_PEER_70_KEY=<stessa chiave>

# 6. Verifica
#    curl -s http://192.168.178.70:8642/health
#    curl -H "Authorization: Bearer $HERMES_PEER_70_KEY" \
#      http://192.168.178.70:8642/v1/capabilities
```

## Verifica generica

```bash
# test listener
curl -s http://localhost:9191/beacon/test-peer
# check log
tail -5 ~/.hermes/peer-status/beacon.log
# run monitor manual
bash ~/.hermes/scripts/faro-monitor.sh
# query status
python3 ~/.hermes/scripts/faro.py
```

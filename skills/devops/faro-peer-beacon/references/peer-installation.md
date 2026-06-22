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

## Verifica

```bash
curl -s http://localhost:9191/beacon/test-peer     # test listener
tail -5 ~/.hermes/peer-status/beacon.log            # check log
bash ~/.hermes/scripts/faro-monitor.sh              # run monitor manual
python3 ~/.hermes/scripts/faro.py                   # query status
```
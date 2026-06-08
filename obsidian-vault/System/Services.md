# Services

## butler.service

Servizio systemd di sistema per ScienceClick2 / Domotz Butler.

Comandi utili:

```bash
sudo systemctl restart butler.service
systemctl status butler.service --no-pager --lines=30
```

Dettagli osservati:

- unit file: `/etc/systemd/system/butler.service`;
- working command: `/bin/bash /home/fausto/Software/ScienceClick2/service_start.sh`;
- app Next.js su `http://localhost:3001`;
- URL rete osservato: `http://192.168.178.84:3001`.

Nota: npm può stampare warning su Node.js v24.15.0, ma il servizio può comunque partire correttamente.

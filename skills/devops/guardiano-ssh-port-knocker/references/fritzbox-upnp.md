# FritzBox UPnP IGD — Port Forwarding via miniupnpc

## FritzBox locale
- IP: 192.168.178.1
- UPnP IGD: http://192.168.178.1:49000/igddesc.xml
- Control endpoint: http://192.168.178.1:49000/igdupnp/control/WANIPConn1
- UPnP porte aperte: 49000 (IGD), 49001
- WAN: 151.29.74.249 (dinamico, cambia col riavvio FritzBox)
- Link: 14.4 Mbps down / 10.5 Mbps up

## upnpc utility
- Pacchetto: `miniupnpc` (gia installato su N56VV)
- Binary: `upnpc`

## Query stato

```bash
# Elenco completo mappature + stato connessione
upnpc -l
```

Output tipico:
```
Found valid IGD : http://192.168.178.1:49000/igdupnp/control/WANIPConn1
Local LAN ip address : 192.168.178.84
Connection Type : IP_Routed
Status : Connected, uptime=Ns
ExternalIPAddress = 151.29.74.249
 i protocol exPort->inAddr:inPort description remoteHost leaseTime
 0 TCP 51413->192.168.178.84:51413 'Transmission.at.51413' '' 0
 1 UDP 51413->192.168.178.84:51413 'Transmission.at.51413' '' 0
```

## Gestione regole

```bash
# Aggiungere: -a <IP_LAN> <porta_LAN> <porta_WAN> <protocollo>
upnpc -a 192.168.178.70 22 2222 TCP

# Rimuovere: -d <porta_WAN> <protocollo>
upnpc -d 2222 TCP

# Verificare IP esterno
upnpc -l | grep ExternalIPAddress
```

Le regole UPnP su FritzBox hanno leaseTime=0 (permanenti). NON si autochiudono.

## Stato attuale (al 14 luglio 2026)

Solo Transmission (51413 TCP/UDP) ha regole UPnP. Nessun port forwarding per 2222 o 3001.

## Architettura WAN

Due scenari:

### 1. Diretto su peer84 (N56VV)
```
WAN:2222 --[UPnP]--> peer84(LAN):2222 --[iptables Guardiano]--> peer84:22
```
Usato quando N56VV e' in finestra di lavoro (non cooling). Richiede Guardiano attivo per limitare esposizione.

### 2. Jump host via peer70 (RPi, sempre-on)
```
WAN:2222 --[UPnP]--> peer70(LAN):22 --[SSH -J]--> peer128(LAN):22
```
Peer70 (192.168.178.70, RPi Debian 11) e' sempre acceso, senza limiti termici. Ideale per accesso 24/7 al Mac peer128. Il comando SSH da fuori:

```bash
ssh -J fausto@151.29.74.249 -p 2222 fausto@192.168.178.128
```

Ovvero: SSH sulla WAN:2222 (arriva a peer70:22), poi da li' salto a peer128:22.

## Note
- IP WAN dinamico: se il FritzBox riavvia, l'IP potrebbe cambiare. Serve DDNS o verifica periodica.
- UPnP non e' la stessa cosa della configurazione manuale delle port forwarding nel FritzBox web UI. Le regole UPnP sono visibili anche nella UI sotto "Freigaben" -> "Portfreigaben".
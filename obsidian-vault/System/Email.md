# Email

## User preference

- Use Gmail by default for checking email.
- Use the configured Virgilio account for sending unless the user specifies otherwise.

## Himalaya / Virgilio sending setup

Himalaya is installed at:

```text
/home/fausto/.local/bin/himalaya
```

Observed version: `1.2.0`.

Configured account:

```text
virgilio
```

Email address:

```text
fausto.lelli@virgilio.it
```

Config path:

```text
/home/fausto/.config/himalaya/config.toml
```

Password command reads:

```text
/home/fausto/.config/himalaya/virgilio.pass
```

via:

```text
/home/fausto/.config/himalaya/virgilio-password
```

Preferred send command:

```bash
himalaya template send -a virgilio
```

Caveat: `himalaya message send` crashed once with a mail-parser index-out-of-bounds error.

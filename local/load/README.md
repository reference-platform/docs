# Load tests

[k6](https://k6.io) scripts that test the platform from the outside.

- `smoke.js`: a smoke test. It checks that k6 works and can reach a target.

## Requirements

- k6. See the [install guide](https://grafana.com/docs/k6/latest/set-up/install-k6/)
  for Linux, macOS and Windows.
- Python 3, only to start the sample target below.

## Run

Start a sample target in one terminal:

```
python3 -m http.server 8000
```

On Windows, use `python` instead of `python3`.

Run the script in another terminal:

```
k6 run smoke.js
```

## Run against another machine

Set `BASE_URL` to the address of the machine that runs the target:

```
k6 run -e BASE_URL=http://<target-ip>:8000 smoke.js
```

The target must listen on all interfaces and the firewall must allow the port.

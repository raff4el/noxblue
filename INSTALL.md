# Installing noxblue

> [!WARNING]
> Rebasing to a custom image is [experimental](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable).
> Keep `rpm-ostree rollback` and a TTY in mind in case the session does not come up.

## From stock Fedora Atomic

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/raff4el/noxblue:latest
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/raff4el/noxblue:latest
systemctl reboot
```

## From secureblue

secureblue's container policy rejects anything not explicitly listed, so the
unsigned first step above fails before it starts. Trust the key first, then
rebase signed directly:

```bash
git clone https://github.com/raff4el/noxblue && cd noxblue

# 1. Trust the signing key
run0 install -Dm644 cosign.pub /etc/pki/containers/noxblue.pub

# 2. Declare that the repository carries sigstore attachments. Same path and
#    content the image itself ships, so this is only pre-creating it.
printf 'docker:\n  ghcr.io/raff4el/noxblue:\n    use-sigstore-attachments: true\n' \
  > /tmp/noxblue-registry.yaml
run0 install -Dm644 /tmp/noxblue-registry.yaml \
  /etc/containers/registries.d/raff4el-noxblue.yaml

# 3. Add the policy entry
python3 - <<'PY'
import json, pathlib
p = json.loads(pathlib.Path('/etc/containers/policy.json').read_text())
p['transports']['docker']['ghcr.io/raff4el/noxblue'] = [{
    'type': 'sigstoreSigned',
    'keyPath': '/etc/pki/containers/noxblue.pub',
    'signedIdentity': {'type': 'matchRepository'},
}]
pathlib.Path('/tmp/policy.json').write_text(json.dumps(p, indent=4) + '\n')
PY
run0 cp /etc/containers/policy.json /etc/containers/policy.json.bak
run0 install -Dm644 /tmp/policy.json /etc/containers/policy.json

# 4. Rebase
run0 -i rpm-ostree rebase ostree-image-signed:docker://ghcr.io/raff4el/noxblue:latest
systemctl reboot
```

Use `sudo` in place of `run0` if your image still has it.

### After the first boot

Hand the three files back to the image. ostree keeps local edits in `/etc`
forever, so your copies would otherwise shadow a rotated key:

```bash
run0 cp /usr/etc/containers/policy.json /etc/containers/policy.json
run0 cp /usr/etc/pki/containers/noxblue.pub /etc/pki/containers/noxblue.pub
run0 cp /usr/etc/containers/registries.d/raff4el-noxblue.yaml /etc/containers/registries.d/
run0 rm /etc/containers/policy.json.bak
run0 ostree admin config-diff | grep -E 'containers|pki'   # expect no output
```

If your account existed before the rebase, also copy
`/etc/skel/.config/noctalia/config.toml` into `~/.config/noctalia/`, or
Noctalia's polkit agent stays off and `run0` from the launcher fails silently.

## Updates and verification

`latest` follows new builds but stays on the Fedora release pinned in
`recipes/recipe.yml`. Verify the image independently with:

```bash
cosign verify --key cosign.pub ghcr.io/raff4el/noxblue
```

# Hearth

A private local runtime for small personal tools.

Hearth turns your laptop or home computer into an app server you control. You install a small app, manage it from a dashboard and a command line, and open it from your phone on the same Wi-Fi.

There is no cloud account and no monthly hosting bill. Your notes, expenses, and other app data stay on this computer, under `~/.hearth`.

**This beta supports macOS and Linux.** Windows is unsupported. The binary is not code-signed.

This repository publishes the installer and the release binaries. The Hearth source is private.

---

## Who it is for

Hearth is for people who already make small tools with ChatGPT, Claude, Cursor, or a local script, and want those tools to stay running.

A good fit looks like this:

- A notes app, checklist, workout log, or expense tracker you actually open again tomorrow
- A utility an AI session generated, saved as one ZIP, and you want on your own machine
- Access from your phone while you are on the same home Wi-Fi
- One person, on a computer you trust, running apps you trust

You should be comfortable using a terminal during this beta. Setup is a few commands. Some home routers block phone access, and the docs below tell you how to check that.

## What you can do with it

After install, Hearth gives you:

- A local dashboard at `http://localhost:8080`
- A command-line tool, `hearth`, to install, start, stop, and inspect apps
- A built-in gallery of starter apps that install with no Go toolchain
- A place to drop a ZIP of a small Python, Node, Ruby, Go, or HTML app
- One gateway address for every app: `http://localhost:8080/apps/<name>/`
- A QR code on the dashboard so a phone on the same Wi-Fi can open the dashboard
- Optional start-on-login (launchd on macOS, systemd on Linux)
- Backup and restore of Hearth's local state and app data
- `hearth doctor` when something in setup does not look right

Gallery starters already in the release:

| App | What it is |
|---|---|
| `notes` | Notes stored on this computer. A phone on the same Wi-Fi sees the same notes. |
| `quick-notes` | A scratchpad in the browser. Notes stay in that browser only. |
| `home-checklist` | A recurring checklist for chores, packing, medications, pets, and routines. |
| `snippet-vault` | A local vault for prompts, shell commands, links, and snippets. |
| `expense-tracker` | Subscriptions and one-off expenses (monthly, yearly, weekly, one-time). |
| `gym-log` | A workout log: date, exercise, and sets. |

`quick-notes` is static HTML. The other five ship inside the Hearth binary, so you do not need Go installed to run them.

## What this beta does not do

Read this before you install. These are current product limits, not temporary bugs.

- **Windows is unsupported.** There is no Windows installer and no native Windows build. WSL2 is untested. Do not treat a Windows machine as a supported beta path.
- **Apps are not sandboxed.** Each app runs as your user. It can read and write the same files you can. Hearth is for apps you trust. It is not a place to run a ZIP from someone you do not trust.
- **One person.** There are no accounts, teams, or per-user permissions.
- **No cloud copy of your data.** Opening Hearth on your phone does not sync a second copy to the phone. The phone is another browser talking to this computer. If this computer is off, the apps are off.
- **Home Wi-Fi is the normal phone path.** Some routers isolate Wi-Fi clients from each other. When that happens, the phone cannot open the laptop. `hearth tunnel` can expose the dashboard on the internet as a fallback. Turn it off when you are done. It is not the default way to use Hearth.
- **The binary is not code-signed.** macOS may warn the first time you run it. The installer checks a SHA-256 checksum before it installs, and it stops if the checksum does not match.
- **Uploaded Go apps need Go on your PATH.** Gallery starters do not. A ZIP whose entry file is `main.go` does.
- **Next.js, Vite, Nuxt, and Docker are refused.** Build the site first and zip the output so `index.html` is at the top of the ZIP.
- **LAN traffic is HTTP unless you opt into HTTPS.** `hearth up --tls` serves HTTPS on port 8443. Each phone must trust Hearth's local certificate authority. Until it does, use the HTTP QR link on a Wi-Fi network you trust.
- **App pages are not individually logged in.** The dashboard asks for an access code from another device. The apps behind `/apps/<name>/` do not. Only run them on a network where that is acceptable.
- **mDNS names are optional and uneven.** `my-app.hearth.local` works on some networks and not others. The address that always works on this computer is `http://localhost:8080/apps/<name>/`.

Out of scope for this beta: a public app store, multi-user hosting, a native phone app, and running untrusted code.

---

## Install

**Supported**

| System | Architecture |
|---|---|
| macOS | Apple Silicon (`arm64`) and Intel (`amd64`) |
| Linux | `amd64` and `arm64` |

**Unsupported:** Windows. The installer exits if it sees another OS or CPU.

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/AmirS0hail-labs/hearth-releases/main/install.sh | bash
```

What that script does:

1. Detects macOS or Linux, and `arm64` or `amd64`.
2. Downloads the newest release from this repository.
3. Downloads `SHA256SUMS` and checks the file before it is installed.
4. Copies `hearth` onto your `PATH`.

Install location:

- `/opt/homebrew/bin/hearth` on a Mac where Homebrew's bin directory is already on `PATH`
- `/usr/local/bin/hearth` otherwise

If that directory is not writable, the script asks for your password through `sudo`.

Pin a version, or choose the directory:

```bash
curl -fsSL https://raw.githubusercontent.com/AmirS0hail-labs/hearth-releases/main/install.sh | HEARTH_VERSION=v0.1.0-beta.1 bash
```

```bash
curl -fsSL https://raw.githubusercontent.com/AmirS0hail-labs/hearth-releases/main/install.sh | HEARTH_INSTALL_DIR="$HOME/.local/bin" bash
```

`HEARTH_INSTALL_DIR` must already be on `PATH`.

Check the install:

```bash
hearth version
```

You should see the release tag, for example `v0.1.0-beta.1`.

Hearth does not phone home. It does not report installs, app names, or anything under `~/.hearth`. The only download totals are GitHub's per-file counts on [Releases](https://github.com/AmirS0hail-labs/hearth-releases/releases).

If no release exists yet for your system, the installer prints the URL and stops. It will not clone source or compile anything.

### Remove it

Stop the background service if you installed one, then delete the binary:

```bash
hearth service uninstall
rm -f /opt/homebrew/bin/hearth /usr/local/bin/hearth
```

App data, the access token, and logs stay in `~/.hearth` until you delete that folder yourself. Deleting it removes every installed app's local data.

---

## First run

### 1. Start Hearth

```bash
hearth up
```

This starts Hearth in the foreground, prints an access code, and opens the dashboard in your browser.

- Dashboard: `http://localhost:8080`
- If 8080 is busy, Hearth tries the next free port through 8099 and prints that URL
- Each app listens on its own port in 9100–9999; you normally open the app through the dashboard, not that port

Leave this terminal open. Closing it stops Hearth.

To start on login instead:

```bash
hearth service install
hearth service status
```

Remove that with `hearth service uninstall`.

### 2. Install a starter app

From the dashboard gallery, or:

```bash
hearth gallery
hearth gallery install notes
```

Then open:

- Dashboard: `http://localhost:8080`
- The app: `http://localhost:8080/apps/notes/`

Try one real task. Add a note, a checklist item, or an expense. Confirm it is still there after you stop and start Hearth again.

### 3. Open it on your phone

1. Connect the phone to the same Wi-Fi as this computer. Turn off mobile data for the test if the phone prefers cellular.
2. On the dashboard, open Phone Access and scan the QR code.
3. The phone should load the dashboard. From there, open the app.

You do not need `hearth tunnel` for this. The phone is another browser pointed at this computer. Notes and expenses remain in `~/.hearth/apps/<name>/data/`.

If the phone says it cannot reach the site, run:

```bash
hearth doctor
```

Typical causes: the phone is on guest Wi-Fi, the router isolates clients, the Mac firewall is blocking the port, or the two devices are on different subnets. Guest networks and "AP isolation" often block this on purpose.

`hearth tunnel start` publishes a temporary public HTTPS address through Cloudflare as a fallback. Stop it with `hearth tunnel stop` when you are finished. A public address is reachable by anyone who has the link. Remote management still asks for the access code.

### 4. Optional HTTPS on this computer

```bash
hearth up --tls
hearth trust-ca
```

HTTPS listens on port 8443. A phone will keep showing a certificate warning until that phone trusts Hearth's local CA. For a first phone test, HTTP on your own Wi-Fi is the simpler path.

---

## Bring your own app

The usual path is a ZIP from a ChatGPT, Claude, or Cursor session. On the dashboard, drop the ZIP. You can also install it from the terminal:

```bash
hearth install my-app.zip
hearth start my-app
```

Give the AI this contract:

```text
Build a small Hearth app and give me one ZIP file.

Put exactly one of these files at the top of the ZIP: app.py, server.js, app.rb, main.go, or index.html.

The app must:
- Listen on the PORT environment variable. Bind 0.0.0.0:$PORT.
- Write files only under HEARTH_DATA_DIR.
- Use relative links so the app works under /apps/<name>/.

Do not use Next.js, Vite, Nuxt, Docker, or any build step. Do not hard-code a port or a root URL.
```

Hearth accepts a ZIP with no `app.json` when it can tell the app type from the filenames. An explicit bundle looks like this:

```text
my-app/
├── app.json
├── app.py
└── ...
```

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "main": "app.py",
  "language": "python",
  "env": {
    "MY_VAR": "value"
  }
}
```

| Field | Required | Meaning |
|---|---|---|
| `name` | Yes, or inferred from the ZIP name | Lowercase letters, numbers, and hyphens. Maximum 32 characters. |
| `version` | No | Defaults to `0.1.0`. |
| `main` or `entry` | Yes for a running app, or inferred | File Hearth should launch. Not used for `static`. |
| `language` or `runtime` | Yes, or inferred | `python`, `node`, `ruby`, `go`, `static`, or `custom`. |
| `port` | No | `0` lets Hearth assign a port. Leave it at `0`. |
| `command` | For `custom` only | Executable plus arguments. No shell. |
| `env` | No | Extra environment variables. |

| Runtime | How it runs | What you need installed |
|---|---|---|
| `python` | `python3 <entry>` | Python 3 |
| `node` | `node <entry>` | Node.js |
| `ruby` | `ruby <entry>` | Ruby |
| `go` | Compiled once with `go build`, then the binary runs | Go, at install time |
| `static` | Hearth serves the files | Nothing |
| `custom` | The `command` field, split into an executable and arguments | That executable on `PATH` |

Hearth sets these variables for the app:

| Variable | Meaning |
|---|---|
| `PORT` | Port the app must listen on |
| `APP_NAME` | App name |
| `HEARTH_DATA_DIR` | Directory for files that should survive an update |

Write saved data only under `HEARTH_DATA_DIR`. Files outside that directory can disappear when the app is updated.

A ZIP is refused when it needs a build Hearth does not run (Dockerfile, Next.js, Vite, Nuxt, and similar). Zip the built files so `index.html` is at the top. ZIPs over 256 MB are refused. If install or start fails, the dashboard shows one next step: add one of the five entry files, install the missing interpreter, listen on `PORT`, rename a duplicate, or shrink the ZIP.

Update or replace an app you already installed:

```bash
hearth update my-app.zip
hearth install --force my-app.zip
```

---

## Everyday commands

| Command | What it does |
|---|---|
| `hearth up` | Start Hearth in the foreground and open the dashboard |
| `hearth up --tls` | Start with HTTPS on port 8443 |
| `hearth down` | Stop Hearth |
| `hearth service install` | Start Hearth on login |
| `hearth service uninstall` | Remove the login service |
| `hearth service status` | Show whether the login service is running |
| `hearth gallery` | List starter apps |
| `hearth gallery install <name>` | Install a starter app |
| `hearth install <file.zip>` | Install a ZIP |
| `hearth update <file.zip>` | Update an installed app from a ZIP |
| `hearth start <app>` | Start an app |
| `hearth stop <app>` | Stop an app |
| `hearth restart <app>` | Restart an app |
| `hearth remove <app>` | Uninstall an app |
| `hearth list` | List apps and whether they are running |
| `hearth logs <app>` | Show recent output from an app |
| `hearth backup [file.tar.gz]` | Archive state, the access token, and apps |
| `hearth restore <file.tar.gz>` | Restore that archive |
| `hearth token show` | Print the access code |
| `hearth token rotate` | Replace the access code. Old phone links stop working. |
| `hearth doctor` | Check ports, LAN addresses, the token file, TLS files, and common runtimes |
| `hearth setup-dns` | Print optional `hearth.local` instructions |
| `hearth tunnel start` | Temporary public URL. Fallback only. |
| `hearth tunnel stop` | Stop that public URL |
| `hearth tunnel status` | Show whether the tunnel is running |
| `hearth trust-ca` | Trust Hearth's local HTTPS certificate on this computer |
| `hearth status` | Show whether Hearth is running |
| `hearth version` | Print the installed version |

Open addresses:

- This computer: `http://localhost:8080`
- An app on this computer: `http://localhost:8080/apps/<name>/`
- Optional name, after DNS or mDNS works: `http://<name>.hearth.local:8080`
- Phone: the QR code on the dashboard, same Wi-Fi

`hearth setup-dns` prints per-system instructions. A manual hosts-file entry is only for this computer:

```text
127.0.0.1  hearth.local
127.0.0.1  my-app.hearth.local
```

When a name does not resolve, use `/apps/<name>/`.

---

## Where your data lives

Everything Hearth keeps is on this computer:

```text
~/.hearth/
├── state.json          # which apps are installed
├── auth_token          # access code (mode 0600)
├── hearth.pid
├── daemon.log
├── apps/
│   └── notes/
│       ├── manifest.json
│       └── data/       # the app's saved files (HEARTH_DATA_DIR)
├── logs/
│   └── notes.log
└── certs/              # only after you use HTTPS
```

Dashboard **Logs**, and `hearth logs <app>`, show the app process output. Adding an expense or a note does not print a line there unless the app itself logs that action.

`hearth backup` writes an archive of that state. Keep the archive somewhere you control. It contains the access token.

---

## Security, in plain language

Hearth is for trusted apps on a trusted home network.

- The admin API listens on `127.0.0.1:9550` only. Other devices reach the dashboard through the gateway (port 8080, or 8443 with HTTPS) and must present the access code.
- The access code is created the first time Hearth starts and stored in `~/.hearth/auth_token`. Run `hearth token rotate` if a QR link was shared more widely than you wanted.
- A phone that has scanned the QR can manage Hearth until you rotate that code.
- Apps run as you. They are not isolated the way Docker or a virtual machine would isolate them. A hostile ZIP can read files your user can read.
- ZIP install blocks path escape (`../` out of the app directory) and oversized archives. That is not a sandbox.
- Hosted app pages under `/apps/<name>/` do not ask for a separate login.
- `hearth tunnel start` puts the gateway on the public internet. Stop the tunnel when you are done.
- Default LAN traffic is unencrypted. Use `--tls` when the data is sensitive, and trust the local CA on every device that will open it.

If you would not run the program yourself in a terminal, do not install it into Hearth.

---

## When something fails

Run this first and keep the output:

```bash
hearth doctor
hearth version
hearth list
```

Then check:

1. Is `hearth up` still running, or is the login service installed?
2. Does `http://localhost:8080` open on this computer?
3. Does the app page open at `http://localhost:8080/apps/<name>/`?
4. Is the app's runtime installed (`python3`, `node`, `ruby`, or `go` for an uploaded Go ZIP)?
5. Does the app listen on `PORT` and bind `0.0.0.0`?
6. Is the phone on the same Wi-Fi, with mobile data off for the test?
7. Is the phone on a guest network, or is the router isolating Wi-Fi clients?
8. Is the macOS or Linux firewall blocking the dashboard port?

Logs for one app:

```bash
hearth logs notes
```

---

## Beta

This is an early private beta. Expect rough edges in install, phone access, and apps that ignore `PORT` or hard-code a root URL.

Please include this when you report a problem:

- Operating system and version
- Mac or PC, and Apple Silicon or Intel (`hearth version`)
- The install command you ran
- The command that failed, and what you expected
- What happened instead
- The full output of `hearth doctor`
- Whether you were on `localhost`, a LAN address, `hearth.local`, or the phone QR

File that on this repository: [Issues](https://github.com/AmirS0hail-labs/hearth-releases/issues).

Useful titles name the platform and the step, for example `macOS arm64: phone QR cannot reach dashboard on home Wi-Fi`.

---

## This repository

| Path | What it is |
|---|---|
| `install.sh` | The script the `curl` command downloads |
| [Releases](https://github.com/AmirS0hail-labs/hearth-releases/releases) | `hearth-darwin-arm64`, `hearth-darwin-amd64`, `hearth-linux-amd64`, `hearth-linux-arm64`, and `SHA256SUMS` |

Source code is not published here. Do not open issues asking for the private tree.

Each release is built for those four systems, with the gallery starters embedded. Checksums are in `SHA256SUMS` on the same release. The installer refuses a download that does not match.

---

*Hearth — run your tools at home.*

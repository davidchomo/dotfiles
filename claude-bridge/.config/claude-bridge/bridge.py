#!/usr/bin/env python3
"""Local OpenAI-compatible bridge: end-4 sidebar chat -> Claude Code (`claude -p`).

The end-4 (illogical-impulse) "Intelligence" sidebar speaks the OpenAI streaming chat API.
This server accepts those requests on 127.0.0.1 only and runs the user's own Claude Code CLI
(subscription login, not an API key) with --dangerously-skip-permissions, streaming text back as
`content` and a list of tool steps as `reasoning` (shown by end-4 as a collapsed block).

Conversation mapping: a request with a single user message starts a new Claude Code session;
later messages resume the last session (`--resume`). `/clear` in the sidebar = new session.

Security: binds to 127.0.0.1, rejects browser requests (Origin header) and requires the secret
token from ~/.config/claude-bridge/token in the JSON body field "bridge_token".
"""
import hmac
import json
import os
import pathlib
import signal
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST, PORT = "127.0.0.1", 8742
HOME = pathlib.Path.home()
TOKEN = (HOME / ".config/claude-bridge/token").read_text().strip()
STATE = HOME / ".local/state/claude-bridge/session.json"
CLAUDE = os.environ.get("CLAUDE_BIN", str(HOME / ".local/bin/claude"))
SETTINGS = HOME / ".config/rice/settings.json"   # written by the settings app (RiceSettings.qml)
CLAUDE_DEFAULTS = {"enabled": True, "model": "", "permissions": "all", "language": "sk",
                   "style": "short", "workdir": "~"}
WRITE_TOOLS = "Bash Edit Write MultiEdit NotebookEdit"


def claude_settings():
    """Current Claude section of the settings file (re-read on every request)."""
    d = dict(CLAUDE_DEFAULTS)
    try:
        d.update(json.loads(SETTINGS.read_text()).get("claude", {}))
    except (OSError, ValueError):
        pass
    return d


def append_prompt(cfg):
    lang = "English" if cfg.get("language") == "en" else "Slovak"
    style = ("Give thorough, detailed answers with explanations."
             if cfg.get("style") == "detailed" else "Keep answers short.")
    perm = {"all": "", "edit": " You may read and edit files but cannot run shell commands.",
            "read": " You are read-only: you can read files and search the web but not change anything."}
    return ("You are running inside the desktop sidebar chat (end-4 / Quickshell on Hyprland) on the "
            f"user's own computer (CachyOS). Answer in {lang} unless asked otherwise. {style} Use Markdown. "
            "You have no sudo password: when something needs sudo, give the user the exact command and "
            "explain it instead of trying to run it." + perm.get(cfg.get("permissions"), ""))


lock = threading.Lock()  # one Claude Code run at a time


def load_session():
    try:
        return json.loads(STATE.read_text()).get("session")
    except (OSError, ValueError):
        return None


def save_session(sid):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps({"session": sid, "updated": time.time()}))


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):  # OpenAI content parts
        return "\n".join(p.get("text", "") for p in content if isinstance(p, dict))
    return ""


# tool name -> (icon, Slovak verb, input field shown)
TOOL_STYLE = {
    "Bash": ("▶️", "Spúšťam", "command"),
    "Read": ("📄", "Čítam", "file_path"),
    "Write": ("📝", "Zapisujem", "file_path"),
    "Edit": ("✏️", "Upravujem", "file_path"),
    "MultiEdit": ("✏️", "Upravujem", "file_path"),
    "NotebookEdit": ("✏️", "Upravujem", "notebook_path"),
    "Grep": ("🔍", "Hľadám", "pattern"),
    "Glob": ("🔍", "Hľadám súbory", "pattern"),
    "WebSearch": ("🌐", "Hľadám na webe", "query"),
    "WebFetch": ("🌐", "Otváram", "url"),
    "Task": ("🤖", "Spúšťam agenta", "description"),
    "Agent": ("🤖", "Spúšťam agenta", "description"),
    "TodoWrite": ("☑️", "Plánujem kroky", None),
}


def describe_tool(name, inp):
    """One quiet markdown list item per step, e.g. '- 📄 Čítam `~/.config/x`'."""
    inp = inp or {}
    icon, verb, field = TOOL_STYLE.get(name, ("⚙️", name, None))
    val = inp.get(field) if field else None
    if val is None:
        val = next((inp[k] for k in ("command", "file_path", "path", "pattern", "query", "url") if inp.get(k)), None)
    if not val:
        return f"- {icon} {verb}"
    val = str(val).replace(str(HOME), "~").replace("\n", " ").strip()
    if len(val) > 90:
        val = val[:87] + "…"
    return f"- {icon} {verb} `{val}`"


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):  # quieter journal
        sys.stderr.write("bridge: " + fmt % args + "\n")

    def deny(self, code, msg):
        body = json.dumps({"error": {"message": msg}}).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def chunk(self, delta=None, usage=None):
        payload = {"choices": [{"index": 0, "delta": delta or {}}]}
        if usage:
            payload["usage"] = usage
        self.send_raw(f"data: {json.dumps(payload, ensure_ascii=False)}\n\n")

    def flush_narration(self, parts):
        text = "".join(parts).strip()
        if text:
            self.chunk({"reasoning": f"- 💬 *{text.splitlines()[0][:120]}*\n"})

    def send_raw(self, s):
        data = s.encode()
        self.wfile.write(f"{len(data):x}\r\n".encode() + data + b"\r\n")
        self.wfile.flush()

    def do_POST(self):
        if self.path.rstrip("/") != "/v1/chat/completions":
            return self.deny(404, "not found")
        if self.headers.get("Origin"):
            return self.deny(403, "browser requests are not allowed")
        if not self.headers.get("Content-Type", "").startswith("application/json"):
            return self.deny(415, "application/json required")
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
        except (ValueError, OSError):
            return self.deny(400, "bad json")
        if not hmac.compare_digest(str(body.get("bridge_token", "")), TOKEN):
            return self.deny(401, "bad token")

        users = [m for m in body.get("messages", []) if m.get("role") == "user"]
        if not users:
            return self.deny(400, "no user message")
        prompt = text_of(users[-1].get("content"))
        resume = load_session() if len(users) > 1 else None

        if not claude_settings().get("enabled", True):
            return self.deny(503, "Claude Code je v nastaveniach vypnutý")

        if not lock.acquire(blocking=False):
            return self.deny(429, "Claude Code ešte pracuje na predošlej požiadavke")
        try:
            self.run_claude(prompt, resume)
        finally:
            lock.release()

    def run_claude(self, prompt, resume):
        cfg = claude_settings()
        cmd = [CLAUDE, "-p", "--output-format", "stream-json", "--verbose",
               "--include-partial-messages",
               # no MCP servers/claude.ai connectors: they can't authenticate headless and
               # only add noise to answers
               "--strict-mcp-config",
               "--append-system-prompt", append_prompt(cfg)]
        perms = cfg.get("permissions", "all")
        if perms == "all":
            cmd += ["--dangerously-skip-permissions"]
        elif perms == "edit":
            cmd += ["--permission-mode", "acceptEdits", "--disallowedTools", "Bash"]
        else:  # read: headless runs deny anything that would need approval; block writes explicitly
            cmd += ["--disallowedTools", WRITE_TOOLS]
        if cfg.get("model"):
            cmd += ["--model", cfg["model"]]
        workdir = pathlib.Path(os.path.expanduser(cfg.get("workdir") or "~"))
        if not workdir.is_dir():
            workdir = HOME
        if resume:
            cmd += ["--resume", resume]

        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Transfer-Encoding", "chunked")
        self.end_headers()

        proc = subprocess.Popen(cmd, cwd=workdir, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, text=True, start_new_session=True)
        proc.stdin.write(prompt)
        proc.stdin.close()
        got_result = False
        # Text of each model turn is buffered until the turn ends: a turn that also calls tools is
        # just narration ("let me check…") and goes into the collapsed step list; only the final
        # turn without tools becomes the answer. This keeps the sidebar as one step block on top
        # and one uninterrupted answer below it.
        turn_text, turn_has_tools = [], False
        try:
            for line in proc.stdout:
                try:
                    ev = json.loads(line)
                except ValueError:
                    continue
                t = ev.get("type")
                if ev.get("session_id"):
                    save_session(ev["session_id"])
                if t == "stream_event":
                    e = ev.get("event", {})
                    et = e.get("type")
                    if et == "message_start":
                        turn_text, turn_has_tools = [], False
                    elif et == "content_block_start" and e.get("content_block", {}).get("type") == "tool_use":
                        turn_has_tools = True
                        self.flush_narration(turn_text)  # narration belongs before its step
                        turn_text = []
                    elif et == "content_block_delta" and e.get("delta", {}).get("type") == "text_delta":
                        turn_text.append(e["delta"].get("text", ""))
                    elif et == "message_stop":
                        text = "".join(turn_text).strip()
                        if text and turn_has_tools:
                            self.flush_narration(turn_text)
                        elif text:
                            self.chunk({"content": text})
                        turn_text = []
                elif t == "assistant":
                    for c in ev.get("message", {}).get("content", []):
                        if c.get("type") == "tool_use":
                            self.chunk({"reasoning": describe_tool(c.get("name"), c.get("input")) + "\n"})
                elif t == "user":
                    for c in ev.get("message", {}).get("content", []) or []:
                        if isinstance(c, dict) and c.get("type") == "tool_result" and c.get("is_error"):
                            self.chunk({"reasoning": "  - ⚠️ *skončilo chybou*\n"})
                elif t == "result":
                    got_result = True
                    if ev.get("is_error"):
                        self.chunk({"content": f"\n\n**Chyba:** {ev.get('result') or ev.get('subtype')}"})
                    u = ev.get("usage") or {}
                    inp = (u.get("input_tokens") or 0) + (u.get("cache_read_input_tokens") or 0) + (u.get("cache_creation_input_tokens") or 0)
                    out = u.get("output_tokens") or 0
                    self.chunk(usage={"prompt_tokens": inp, "completion_tokens": out, "total_tokens": inp + out})
            proc.wait()
            if not got_result:
                err = proc.stderr.read().strip()[-500:]
                self.chunk({"content": f"\n\n**Claude Code skončil (kód {proc.returncode})** {err}"})
            self.send_raw("data: [DONE]\n\n")
            self.wfile.write(b"0\r\n\r\n")
            self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            # sidebar "stop" / closed: stop Claude Code too
            try:
                os.killpg(proc.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        finally:
            if proc.poll() is None:
                try:
                    os.killpg(proc.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass


if __name__ == "__main__":
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()

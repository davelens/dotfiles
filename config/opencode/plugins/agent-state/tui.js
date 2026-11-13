import { readdirSync } from "node:fs"
import { createConnection } from "node:net"
import { join } from "node:path"

// Pushes this OpenCode TUI's status to every reader socket in
// $XDG_RUNTIME_DIR/agent-state/ (such as dotshell's ai-agents-monitor). Runs
// in the TUI process rather than the shared background service, so each open
// connection doubles as the liveness signal: a reader drops the agent as soon
// as the TUI exits.
// shortcut: tracks every session in this TUI's directory, so two TUIs in one
// directory report the same status; follow ctx.ui.router if that matters.
export default {
  id: "agent-state",
  setup(ctx) {
    const directory = ctx.location?.directory ?? process.cwd()
    const sessions = new Map() // sessionID → "busy" | "retry"
    const waiting = new Set() // pending permission and form (question) IDs
    let failed = false
    let title = ""
    const sockets = new Map() // reader socket path → connection
    let sent = ""

    const status = () => {
      if (waiting.size) return "input"
      const states = [...sessions.values()]
      if (failed || states.includes("retry")) return "error"
      return states.length ? "busy" : "idle"
    }

    const line = () => JSON.stringify({ provider: "opencode", pid: process.pid, cwd: directory, status: status(), title }) + "\n"

    const send = () => {
      const next = line()
      if (next === sent) return
      sent = next
      for (const socket of sockets.values()) {
        if (!socket.connecting && !socket.destroyed) socket.write(next)
      }
    }

    // Connects to reader sockets that appeared since the last scan, so readers
    // can start (or restart) at any time.
    const connectAll = () => {
      const runtimeDir = process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid()}`
      const dir = join(runtimeDir, "agent-state")
      let names
      try {
        names = readdirSync(dir)
      } catch {
        return // No reader has created the directory yet.
      }
      for (const name of names) {
        const path = join(dir, name)
        if (!name.endsWith(".sock") || sockets.has(path)) continue
        const conn = createConnection(path)
        sockets.set(path, conn)
        conn.unref()
        conn.on("connect", () => conn.write(line()))
        // Monitoring must not interrupt OpenCode; a dead reader just means retrying.
        conn.on("error", () => {})
        conn.on("close", () => {
          if (sockets.get(path) === conn) sockets.delete(path)
        })
      }
    }

    const handlers = {
      "session.execution.started": ({ sessionID }) => {
        sessions.set(sessionID, "busy")
        failed = false
      },
      "session.retry.scheduled": ({ sessionID }) => sessions.set(sessionID, "retry"),
      "session.step.started": ({ sessionID }) => sessions.set(sessionID, "busy"),
      "session.execution.succeeded": ({ sessionID }) => sessions.delete(sessionID),
      "session.execution.interrupted": ({ sessionID }) => sessions.delete(sessionID),
      "session.execution.failed": ({ sessionID }) => {
        sessions.delete(sessionID)
        failed = true
      },
      "session.idle": ({ sessionID }) => sessions.delete(sessionID),
      "permission.asked": ({ id }) => waiting.add(id),
      "permission.replied": ({ requestID }) => waiting.delete(requestID),
      "form.created": ({ form }) => waiting.add(form.id),
      "form.replied": ({ id }) => waiting.delete(id),
      "form.cancelled": ({ id }) => waiting.delete(id),
      "session.created": data => {
        if (!data.parentID && data.title) title = data.title
      },
      "session.renamed": data => {
        if (!ctx.data.session.get(data.sessionID)?.parentID) title = data.title
      },
    }

    const unsubscribe = Object.entries(handlers).map(([type, handle]) =>
      ctx.data.on(type, event => {
        if (event.location && event.location.directory !== directory) return
        handle(event.data)
        send()
      }),
    )

    connectAll()
    const scan = setInterval(connectAll, 5000)
    scan.unref()

    return () => {
      clearInterval(scan)
      for (const off of unsubscribe) off()
      for (const socket of sockets.values()) socket.destroy()
      sockets.clear()
    }
  },
}

import { createConnection } from "node:net"
import { join } from "node:path"

// Pushes this OpenCode TUI's status to dotshell's ai-agents-monitor over its
// Unix socket. Runs in the TUI process rather than the shared background
// service, so the open connection doubles as the liveness signal: dotshell
// drops the agent as soon as the TUI exits.
// shortcut: tracks every session in this TUI's directory, so two TUIs in one
// directory report the same status; follow ctx.ui.router if that matters.
export default {
  id: "dotshell-agents",
  setup(ctx) {
    const directory = ctx.location?.directory ?? process.cwd()
    const sessions = new Map() // sessionID → "busy" | "retry"
    const waiting = new Set() // pending permission and form (question) IDs
    let failed = false
    let title = ""
    let socket
    let sent = ""
    let stopped = false

    const status = () => {
      if (waiting.size) return "input"
      const states = [...sessions.values()]
      if (failed || states.includes("retry")) return "error"
      return states.length ? "busy" : "idle"
    }

    const send = () => {
      if (!socket || socket.connecting || socket.destroyed) return
      const line = JSON.stringify({ provider: "opencode", pid: process.pid, cwd: directory, status: status(), title })
      if (line === sent) return
      sent = line
      socket.write(line + "\n")
    }

    const connect = () => {
      const runtimeDir = process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid()}`
      const conn = createConnection(join(runtimeDir, "dotshell-agents.sock"))
      socket = conn
      conn.unref()
      conn.on("connect", () => {
        sent = ""
        send()
      })
      // Monitoring must not interrupt OpenCode; a missing dotshell just means retrying.
      conn.on("error", () => {})
      conn.on("close", () => {
        if (socket !== conn) return
        socket = undefined
        if (!stopped) setTimeout(connect, 5000).unref()
      })
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

    connect()

    return () => {
      stopped = true
      for (const off of unsubscribe) off()
      socket?.destroy()
    }
  },
}

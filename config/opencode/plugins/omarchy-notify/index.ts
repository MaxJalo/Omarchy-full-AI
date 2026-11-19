import { Plugin } from "@opencode/plugin"
import { execFile } from "node:child_process"

function sendOmarchyNotification(title: string, body: string, urgency: "low" | "normal" | "critical" = "normal") {
  execFile("omarchy-notification-send", ["-u", urgency, "-a", "OpenCode", title, body], () => {
    // Ignore errors when desktop notification daemon is unavailable
  })
}

export default Plugin.define({
  id: "maxjalo.omarchy-notify",
  async setup(ctx) {
    const controller = new AbortController()
    const busySessions = new Set<string>()

    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({
          types: ["session.status", "permission.asked"],
          signal: controller.signal,
        })) {
          if (event.type === "session.status") {
            const props = (event as { properties?: { sessionID?: string; status?: { type?: string } } }).properties
            const sessionID = props?.sessionID
            const statusType = props?.status?.type
            if (!sessionID || !statusType) continue

            if (statusType === "busy") {
              busySessions.add(sessionID)
            } else if (statusType === "idle" && busySessions.has(sessionID)) {
              busySessions.delete(sessionID)
              sendOmarchyNotification("OpenCode", "Задача выполнена и ждёт ответа", "low")
            }
          } else if (event.type === "permission.asked") {
            sendOmarchyNotification("OpenCode", "Требуется подтверждение действия", "normal")
          }
        }
      } catch {
        // Stream aborted during cleanup
      }
    })()

    return () => controller.abort()
  },
})

import { withSupabase } from 'npm:@supabase/server@1.8.1'
import postgres from 'npm:postgres@3.4.9'

const QUEUE_NAME = 'notification_push'
const VISIBILITY_TIMEOUT_SECONDS = 180
const BATCH_SIZE = 20
const MAX_ATTEMPTS = 7
const RETRY_BACKOFF_SECONDS = [30, 60, 120, 300, 900, 1800, 3600]
const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'
const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token'

interface QueueMessage {
  msg_id: bigint | number | string
  read_ct: number
  vt: string
  enqueued_at: string
  message: { delivery_id?: string; version?: number }
}

interface DeliveryRecord {
  id: string
  notification_id: string
  device_id: string
  status: 'queued' | 'processing' | 'sent' | 'invalid' | 'failed'
  attempt_count: number
  available_at: string
  lease_until: string | null
  fcm_token: string
  platform: 'android' | 'ios' | 'web'
  notification_title: string
  notification_body: string
  notification_type: string
  notification_priority: 'low' | 'normal' | 'high' | 'critical'
  notification_data: Record<string, unknown>
}

interface FcmResult {
  ok: boolean
  providerMessageId?: string
  retryable: boolean
  invalidToken: boolean
  code: string
  message: string
}

let cachedAccessToken: string | null = null
let cachedAccessTokenExpiresAt = 0

function requiredSecret(name: string): string {
  const value = Deno.env.get(name)?.trim()
  if (!value) throw new Error(`Missing required secret: ${name}`)
  return value
}

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = ''
  const chunkSize = 0x8000
  for (let i = 0; i < bytes.length; i += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize))
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '')
}

function utf8Bytes(value: string): Uint8Array {
  return new TextEncoder().encode(value)
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '')

  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

async function getFcmAccessToken(serviceAccount: {
  client_email: string
  private_key: string
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  if (cachedAccessToken && cachedAccessTokenExpiresAt > now + 60) {
    return cachedAccessToken
  }

  const header = base64UrlEncode(utf8Bytes(JSON.stringify({
    alg: 'RS256',
    typ: 'JWT',
  })))

  const payload = base64UrlEncode(utf8Bytes(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: FCM_SCOPE,
    aud: GOOGLE_TOKEN_URL,
    iat: now,
    exp: now + 3600,
  })))

  const signingInput = `${header}.${payload}`
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    utf8Bytes(signingInput),
  )

  const assertion = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`

  const response = await fetch(GOOGLE_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  })

  const bodyText = await response.text()
  if (!response.ok) {
    throw new Error(`Google OAuth token request failed (${response.status}): ${bodyText.slice(0, 500)}`)
  }

  const body = JSON.parse(bodyText) as { access_token?: string; expires_in?: number }
  if (!body.access_token) {
    throw new Error('Google OAuth token response did not contain access_token')
  }

  cachedAccessToken = body.access_token
  cachedAccessTokenExpiresAt = now + Math.min(body.expires_in ?? 3600, 3600)
  return body.access_token
}

function normalizeFcmData(
  notification: { id: string; type: string; data: Record<string, unknown> },
): Record<string, string> {
  const result: Record<string, string> = {
    notification_id: notification.id,
    type: notification.type,
  }

  for (const [key, value] of Object.entries(notification.data ?? {})) {
    if (key.startsWith('google.') || key.startsWith('gcm.')) continue
    if (value === null || value === undefined) continue
    result[key] = typeof value === 'string' ? value : JSON.stringify(value)
  }

  return result
}

function buildFcmMessage(delivery: DeliveryRecord, accessToken: string, projectId: string) {
  const priority = delivery.notification_priority === 'high' || delivery.notification_priority === 'critical'
    ? 'HIGH'
    : 'NORMAL'

  const data = normalizeFcmData({
    id: delivery.notification_id,
    type: delivery.notification_type,
    data: delivery.notification_data,
  })

  const message: Record<string, unknown> = {
    token: delivery.fcm_token,
    notification: {
      title: delivery.notification_title,
      body: delivery.notification_body,
    },
    data,
  }

  if (delivery.platform === 'android') {
    message.android = {
      priority,
      notification: {
        channel_id: 'financial_notifications',
        sound: 'default',
      },
    }
  } else if (delivery.platform === 'ios') {
    message.apns = {
      headers: {
        'apns-priority': priority === 'HIGH' ? '10' : '5',
      },
      payload: {
        aps: {
          sound: 'default',
        },
      },
    }
  } else {
    message.webpush = {
      notification: {
        title: delivery.notification_title,
        body: delivery.notification_body,
        requireInteraction: delivery.notification_priority === 'critical',
      },
      fcmOptions: {},
    }
  }

  return {
    endpoint: `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/messages:send`,
    body: { message },
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json; charset=UTF-8',
    },
  }
}

function extractFcmError(payload: unknown): { status: string; fcmErrorCode?: string; message: string } {
  const root = (payload && typeof payload === 'object') ? payload as Record<string, unknown> : {}
  const error = (root.error && typeof root.error === 'object') ? root.error as Record<string, unknown> : {}
  const details = Array.isArray(error.details) ? error.details : []

  let fcmErrorCode: string | undefined
  for (const detail of details) {
    if (!detail || typeof detail !== 'object') continue
    const record = detail as Record<string, unknown>
    if (record['@type'] === 'type.googleapis.com/google.firebase.fcm.v1.FcmError') {
      if (typeof record.errorCode === 'string') fcmErrorCode = record.errorCode
    }
  }

  return {
    status: typeof error.status === 'string' ? error.status : 'UNKNOWN',
    fcmErrorCode,
    message: typeof error.message === 'string' ? error.message : 'FCM request failed',
  }
}

async function sendToFcm(delivery: DeliveryRecord, accessToken: string, projectId: string): Promise<FcmResult> {
  const request = buildFcmMessage(delivery, accessToken, projectId)
  const response = await fetch(request.endpoint, {
    method: 'POST',
    headers: request.headers,
    body: JSON.stringify(request.body),
  })

  const responseText = await response.text()
  let payload: unknown = {}
  try {
    payload = responseText ? JSON.parse(responseText) : {}
  } catch {
    payload = {}
  }

  if (response.ok) {
    const body = payload as { name?: string }
    return {
      ok: true,
      providerMessageId: body.name,
      retryable: false,
      invalidToken: false,
      code: 'OK',
      message: 'Delivered to FCM',
    }
  }

  const parsed = extractFcmError(payload)
  const invalidToken = response.status === 404 || parsed.fcmErrorCode === 'UNREGISTERED'
  const retryable = response.status === 408 || response.status === 429 || response.status === 401 || response.status === 403 || response.status >= 500

  // INVALID_ARGUMENT is intentionally not treated as token-invalid automatically:
  // Firebase documents that it can also indicate a malformed payload.
  return {
    ok: false,
    retryable: invalidToken ? false : retryable,
    invalidToken,
    code: parsed.fcmErrorCode ?? parsed.status,
    message: parsed.message.slice(0, 1000),
  }
}

async function processDelivery(
  sql: ReturnType<typeof postgres>,
  queueMessage: QueueMessage,
  accessToken: string,
  projectId: string,
): Promise<'done' | 'retry' | 'defer' | 'skipped'> {
  const deliveryId = queueMessage.message?.delivery_id
  if (!deliveryId) {
    console.error('Queue message is missing delivery_id', queueMessage.message)
    return 'done'
  }

  const claimed = await sql<DeliveryRecord[]>`
    update public.notification_deliveries d
    set
      status = 'processing',
      attempt_count = d.attempt_count + 1,
      lease_until = now() + interval '2 minutes',
      updated_at = now()
    from public.notification_devices nd, public.notifications n
    where d.id = ${deliveryId}::uuid
      and d.device_id = nd.id
      and d.notification_id = n.id
      and (
        (d.status = 'queued' and d.available_at <= now())
        or (d.status = 'processing' and d.lease_until is not null and d.lease_until < now())
      )
      and nd.is_active = true
    returning
      d.id,
      d.notification_id,
      d.device_id,
      d.status,
      d.attempt_count,
      d.available_at,
      d.lease_until,
      nd.fcm_token,
      nd.platform,
      n.title as notification_title,
      n.body as notification_body,
      n.type as notification_type,
      n.priority as notification_priority,
      n.data as notification_data
  `

  const delivery = claimed[0]
  if (!delivery) {
    const [state] = await sql<{
      status: string
      available_at: string
      lease_until: string | null
      device_active: boolean
    }[]>`
      select d.status, d.available_at, d.lease_until, nd.is_active as device_active
      from public.notification_deliveries d
      join public.notification_devices nd on nd.id = d.device_id
      where d.id = ${deliveryId}::uuid
    `

    if (!state || ['sent', 'invalid', 'failed'].includes(state.status)) return 'skipped'

    if (!state.device_active) {
      await sql`
        update public.notification_deliveries
        set status = 'invalid',
            last_error_code = 'DEVICE_INACTIVE',
            last_error_message = 'FCM device registration is inactive',
            lease_until = null,
            updated_at = now()
        where id = ${deliveryId}::uuid
      `
      return 'skipped'
    }

    return 'defer'
  }

  const result = await sendToFcm(delivery, accessToken, projectId)

  if (result.ok) {
    await sql`
      update public.notification_deliveries
      set
        status = 'sent',
        provider_message_id = ${result.providerMessageId ?? null},
        last_error_code = null,
        last_error_message = null,
        lease_until = null,
        sent_at = now(),
        updated_at = now()
      where id = ${delivery.id}::uuid
        and status = 'processing'
    `

    return 'done'
  }

  if (result.invalidToken) {
    await sql.begin(async (transaction) => {
      await transaction`
        update public.notification_deliveries
        set
          status = 'invalid',
          last_error_code = ${result.code},
          last_error_message = ${result.message},
          lease_until = null,
          updated_at = now()
        where id = ${delivery.id}::uuid
      `

      await transaction`
        update public.notification_devices
        set
          is_active = false,
          updated_at = now()
        where id = ${delivery.device_id}::uuid
      `
    })

    return 'done'
  }

  const attempt = delivery.attempt_count
  const exhausted = attempt >= MAX_ATTEMPTS || !result.retryable

  if (exhausted) {
    await sql`
      update public.notification_deliveries
      set
        status = 'failed',
        last_error_code = ${result.code},
        last_error_message = ${result.message},
        lease_until = null,
        updated_at = now()
      where id = ${delivery.id}::uuid
        and status = 'processing'
    `
    return 'done'
  }

  const backoff = RETRY_BACKOFF_SECONDS[Math.min(attempt - 1, RETRY_BACKOFF_SECONDS.length - 1)]

  await sql`
    update public.notification_deliveries
    set
      status = 'queued',
      available_at = now() + make_interval(secs => ${backoff}),
      last_error_code = ${result.code},
      last_error_message = ${result.message},
      lease_until = null,
      updated_at = now()
    where id = ${delivery.id}::uuid
      and status = 'processing'
  `

  return 'retry'
}

async function runWorker(): Promise<Record<string, number>> {
  const serviceAccountJson = requiredSecret('FCM_SERVICE_ACCOUNT_JSON')
  const projectIdFromEnv = Deno.env.get('FCM_PROJECT_ID')?.trim()

  let serviceAccount: { project_id?: string; client_email: string; private_key: string }
  try {
    serviceAccount = JSON.parse(serviceAccountJson)
  } catch {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON is not valid JSON')
  }

  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    throw new Error('FCM service account JSON is missing client_email/private_key')
  }

  const projectId = projectIdFromEnv || serviceAccount.project_id
  if (!projectId) throw new Error('FCM_PROJECT_ID is required when service account project_id is absent')

  const databaseUrl = requiredSecret('SUPABASE_DB_URL')
  // SUPABASE_DB_URL goes through the Supavisor pooler in "Transaction" mode,
  // which does not support protocol-level prepared statements. Prepared
  // statements would fail intermittently once the connection is recycled
  // between invocations, so prefetch/prepare must stay disabled here.
  const sql = postgres(databaseUrl, {
    max: 3,
    idle_timeout: 10,
    connect_timeout: 10,
    prepare: false,
  })

  let processed = 0
  let delivered = 0
  let retried = 0
  let skipped = 0
  let failed = 0

  try {
    const messages = await sql<QueueMessage[]>`
      select *
      from pgmq.read(${QUEUE_NAME}, ${VISIBILITY_TIMEOUT_SECONDS}, ${BATCH_SIZE})
    `

    if (messages.length === 0) {
      return { processed, delivered, retried, skipped, failed }
    }

    const accessToken = await getFcmAccessToken(serviceAccount)

    for (const message of messages) {
      processed += 1
      try {
        const result = await processDelivery(sql, message, accessToken, projectId)

        if (result === 'done') delivered += 1
        else if (result === 'retry') retried += 1
        else if (result === 'defer') skipped += 1
        else skipped += 1

        // Delete the queue message only when this delivery reached a terminal
        // state. Retryable failures remain in PGMQ and become visible again.
        if (result === 'done' || result === 'skipped') {
          await sql`select pgmq.delete(${QUEUE_NAME}, ${String(message.msg_id)}::bigint)`
        } else if (result === 'defer') {
          await sql`select pgmq.set_vt(${QUEUE_NAME}, ${String(message.msg_id)}::bigint, 15)`
        } else {
          const attempt = Math.max(1, Number(message.read_ct ?? 1))
          const backoff = RETRY_BACKOFF_SECONDS[Math.min(attempt - 1, RETRY_BACKOFF_SECONDS.length - 1)]
          await sql`
            select pgmq.set_vt(
              ${QUEUE_NAME},
              ${String(message.msg_id)}::bigint,
              ${backoff}
            )
          `
        }
      } catch (error) {
        failed += 1
        console.error('Failed processing notification delivery', {
          msg_id: String(message.msg_id),
          error: error instanceof Error ? error.message : String(error),
        })
        // Leave the queue message in place so PGMQ retries it after the
        // visibility timeout. No delivery row is marked sent unless FCM
        // succeeded and the DB update completed.
      }
    }

    return { processed, delivered, retried, skipped, failed }
  } finally {
    await sql.end({ timeout: 5 }).catch(() => undefined)
  }
}

Deno.serve(
  withSupabase({ auth: 'secret:notification_worker' }, async (req) => {
    if (req.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405 })
    }

    try {
      const stats = await runWorker()
      console.log('notification-push-worker completed', stats)
      return Response.json({ ok: true, ...stats })
    } catch (error) {
      console.error('notification-push-worker failed', error)
      return Response.json(
        {
          ok: false,
          error: error instanceof Error ? error.message : String(error),
        },
        { status: 500 },
      )
    }
  }),
)

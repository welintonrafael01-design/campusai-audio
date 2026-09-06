import { randomUUID } from "node:crypto";
import { NextResponse } from "next/server";
import {
  ContactProviderUnavailableError,
  contactClientKey,
  contactPayloadError,
  contactRateLimiter,
  createContactProvider,
  isAllowedContactOrigin,
  parseContactPayload,
} from "@/lib/contact-server";

export const runtime = "nodejs";

const MAX_BODY_BYTES = 8192;

function errorResponse(
  status: number,
  code: string,
  message: string,
  requestId: string,
  headers: Record<string, string> = {},
) {
  return NextResponse.json(
    { ok: false, error: { code, message }, requestId },
    {
      status,
      headers: {
        "Cache-Control": "no-store",
        "X-Request-ID": requestId,
        ...headers,
      },
    },
  );
}

export async function POST(request: Request) {
  const requestId = randomUUID();
  if (!isAllowedContactOrigin(request)) {
    return errorResponse(
      403,
      "origin_denied",
      "No se pudo validar el origen de la solicitud.",
      requestId,
    );
  }
  if (!request.headers.get("content-type")?.startsWith("application/json")) {
    return errorResponse(
      415,
      "content_type_invalid",
      "El formato de la solicitud no es compatible.",
      requestId,
    );
  }

  const rateLimit = contactRateLimiter.consume(contactClientKey(request));
  if (!rateLimit.allowed) {
    return errorResponse(
      429,
      "rate_limited",
      "Has realizado varios intentos. Espera antes de volver a enviar.",
      requestId,
      { "Retry-After": String(rateLimit.retryAfterSeconds) },
    );
  }

  const declaredLength = Number(request.headers.get("content-length") || 0);
  if (declaredLength > MAX_BODY_BYTES) {
    return errorResponse(
      413,
      "payload_too_large",
      "El mensaje supera el tamaño permitido.",
      requestId,
    );
  }

  let body: string;
  try {
    body = await request.text();
  } catch {
    return errorResponse(
      400,
      "payload_invalid",
      "No se pudo leer el mensaje.",
      requestId,
    );
  }
  if (new TextEncoder().encode(body).byteLength > MAX_BODY_BYTES) {
    return errorResponse(
      413,
      "payload_too_large",
      "El mensaje supera el tamaño permitido.",
      requestId,
    );
  }

  let decoded: unknown;
  try {
    decoded = JSON.parse(body);
  } catch {
    return errorResponse(
      400,
      "payload_invalid",
      "No se pudo validar el mensaje.",
      requestId,
    );
  }
  const payload = parseContactPayload(decoded);
  const validationError = payload ? contactPayloadError(payload) : null;
  if (!payload || validationError) {
    return errorResponse(
      400,
      "validation_failed",
      validationError || "No se pudo validar el mensaje.",
      requestId,
    );
  }

  try {
    await createContactProvider().deliver(payload, {
      requestId,
      receivedAt: new Date().toISOString(),
    });
  } catch (error) {
    const unavailable = error instanceof ContactProviderUnavailableError;
    return errorResponse(
      503,
      unavailable ? "contact_unavailable" : "delivery_failed",
      unavailable
        ? "El canal seguro de contacto aún no está habilitado. No se enviaron datos."
        : "No pudimos entregar el mensaje. Inténtalo más tarde.",
      requestId,
    );
  }

  return NextResponse.json(
    {
      ok: true,
      message: "Mensaje recibido. Gracias por contactar a StudyBook AI.",
      requestId,
    },
    {
      status: 202,
      headers: {
        "Cache-Control": "no-store",
        "X-Request-ID": requestId,
      },
    },
  );
}

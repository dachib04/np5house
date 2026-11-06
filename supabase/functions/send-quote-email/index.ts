// Sends an email notification to the sales inbox whenever a quote request is
// submitted from the configurator. The Resend API key lives only here, as a
// Supabase secret — it's never sent to or visible from the browser.
//
// Deploy via Supabase Dashboard → Edge Functions → Deploy a new function,
// name it "send-quote-email", paste this file's contents.
// Then set the secret: Edge Functions → Secrets → add RESEND_API_KEY.

const RECIPIENT = "sales@np5.eu";
// Verified against the live Resend account on 2026-10-31: np5.eu is not yet
// verified as a sending domain there, so nothing can be delivered to
// sales@np5.eu until that's done at resend.com/domains (DNS records needed —
// only whoever controls the np5.eu domain can do this). Once verified, change
// this to a real address on that domain, e.g. "NP5.HOUSE <noreply@np5.eu>".
const SENDER = "NP5.HOUSE <onboarding@resend.dev>";

function escapeHtml(str: unknown): string {
  return String(str ?? "").replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string)
  );
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "POST only" }), { status: 405 });
  }

  const resendKey = Deno.env.get("RESEND_API_KEY");
  if (!resendKey) {
    return new Response(JSON.stringify({ error: "RESEND_API_KEY not configured" }), { status: 503 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400 });
  }

  const name = String(body.name ?? "").slice(0, 200);
  const email = String(body.email ?? "").slice(0, 320);
  const phone = body.phone ? String(body.phone).slice(0, 40) : null;
  const message = body.message ? String(body.message).slice(0, 4000) : null;
  const houseName = body.house_name ? String(body.house_name).slice(0, 200) : "Unknown house";
  const estimatedPrice = body.estimated_price;
  const configuration = Array.isArray(body.configuration) ? body.configuration : [];

  if (!name || !email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return new Response(JSON.stringify({ error: "Missing or invalid name/email" }), { status: 400 });
  }

  const configRows = configuration
    .map((r) => (Array.isArray(r) ? `${escapeHtml(r[0])}: <strong>${escapeHtml(r[1])}</strong>` : null))
    .filter(Boolean)
    .join("<br>");

  const html = `
    <div style="font-family:sans-serif;max-width:560px">
      <h2 style="color:#051D49">New quote request — ${escapeHtml(houseName)}</h2>
      <p><strong>Name:</strong> ${escapeHtml(name)}<br>
      <strong>Email:</strong> ${escapeHtml(email)}<br>
      ${phone ? `<strong>Phone:</strong> ${escapeHtml(phone)}<br>` : ""}
      ${estimatedPrice ? `<strong>Estimated price:</strong> €${escapeHtml(estimatedPrice)}<br>` : ""}
      </p>
      ${message ? `<p><strong>Message:</strong><br>${escapeHtml(message)}</p>` : ""}
      ${configRows ? `<p><strong>Configuration:</strong><br>${configRows}</p>` : ""}
      <p style="color:#888;font-size:12px">Submitted from the NP5.HOUSE configurator.</p>
    </div>
  `;

  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${resendKey}`,
      },
      body: JSON.stringify({
        from: SENDER,
        to: [RECIPIENT],
        reply_to: email,
        subject: `New quote request — ${houseName}`,
        html,
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      return new Response(JSON.stringify({ error: "Resend rejected the email", detail: errText }), { status: 502 });
    }

    return new Response(JSON.stringify({ status: "sent" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: "Could not reach email provider" }), { status: 502 });
  }
});

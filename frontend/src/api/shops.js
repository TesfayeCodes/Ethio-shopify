const BASE_URL = import.meta.env.VITE_API_URL;
async function apiFetch(path, options = {}) {
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      "ngrok-skip-browser-warning": "true",
      "Accept": "application/json",
      ...options.headers,
    },
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || "Request failed");
  }
  return res.json();
}
export async function createShop(data) {
  return apiFetch("/shops", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ shop: data }),
  });
}
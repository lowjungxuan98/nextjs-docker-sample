export const dynamic = "force-dynamic";

export default async function Home() {
  return (
    <main style={{ fontFamily: "ui-sans-serif, system-ui", padding: 24 }}>
      <h1 style={{ fontSize: 20, fontWeight: 600, marginBottom: 12 }}>Next.js Docker Sample</h1>
      <p>env: <strong>{process.env.NODE_ENV || "NONE"}</strong></p>
      <p>NEXT_PUBLIC_SECRET: <code>{process.env.NEXT_PUBLIC_SECRET || "(not set)"}</code></p>
    </main>
  );
}

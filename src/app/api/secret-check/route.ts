export const GET = async () =>
  Response.json({
    ok: true,
    env: process.env.NODE_ENV,
    secretPresent: Boolean(process.env.NEXT_PUBLIC_SECRET),
  });



// Crew server connection. The anon key is meant to be public; the database's access rules protect the data.
// Never put the service_role key here.
window.CREW_CONFIG = {
  url: "",      // e.g. "https://abcdefghijklmnop.supabase.co"
  anonKey: ""   // Supabase → Project Settings → API → "anon public" key
};

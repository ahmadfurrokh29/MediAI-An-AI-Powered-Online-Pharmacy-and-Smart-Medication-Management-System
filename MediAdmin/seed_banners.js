/**
 * seed_banners.js
 * Seeds the Firestore "Banners" collection with 3 real ad banner documents
 * using the Firestore REST API (no firebase-admin needed).
 *
 * Run: node seed_banners.js
 */
const https = require('https');

const PROJECT_ID = 'medi-ai-6bcb2';
const API_KEY    = 'AIzaSyBCgqiXlTYFEJPqmflkVQbspqq5P8A2j_8';

// We need an auth token to write. Since Firestore rules require auth for writes,
// we first sign in as the admin user using Firebase Auth REST API, then use the
// returned idToken.
//
// Replace these with valid admin credentials:
const ADMIN_EMAIL    = process.env.ADMIN_EMAIL    || process.argv[2] || 'admin@mediai.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || process.argv[3] || 'admin123456';

// ── Free, permanently-hosted pharmacy/medicine ad images (Unsplash) ──────
const ADS = [
  {
    title: 'Summer Health Sale',
    description: 'Up to 30% off on all vitamins and supplements this summer!',
    image: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=1200&q=80',
    isActive: true,
  },
  {
    title: 'Free Delivery Today',
    description: 'Order medicines online and get free delivery on orders above Rs. 500',
    image: 'https://images.unsplash.com/photo-1576671081837-49000212a370?w=1200&q=80',
    isActive: true,
  },
  {
    title: 'Trusted Pharmacy',
    description: 'Authentic medicines from certified pharmacies. Shop with confidence.',
    image: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=1200&q=80',
    isActive: true,
  },
];

// ── Helpers ────────────────────────────────────────────────────────────────
function post(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const u = new URL(url);
    const req = https.request(
      {
        hostname: u.hostname,
        path: u.pathname + u.search,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data),
        },
      },
      (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          try { resolve(JSON.parse(raw)); }
          catch { resolve(raw); }
        });
      }
    );
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function firestorePost(path, body, token) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`;
    const req = https.request(
      {
        hostname: 'firestore.googleapis.com',
        path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data),
          'Authorization': `Bearer ${token}`,
        },
      },
      (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          try { resolve(JSON.parse(raw)); }
          catch { resolve(raw); }
        });
      }
    );
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

// Convert a JS value to Firestore REST API field value format
function toFirestoreValue(val) {
  if (typeof val === 'string')  return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number')  return { integerValue: String(val) };
  return { stringValue: String(val) };
}

function toFirestoreDoc(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    fields[k] = toFirestoreValue(v);
  }
  return { fields };
}

// ── Main ───────────────────────────────────────────────────────────────────
(async () => {
  // 1. Sign in
  console.log(`Signing in as ${ADMIN_EMAIL}…`);
  const authRes = await post(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    { email: ADMIN_EMAIL, password: ADMIN_PASSWORD, returnSecureToken: true }
  );

  if (!authRes.idToken) {
    console.error('Auth failed:', JSON.stringify(authRes, null, 2));
    process.exit(1);
  }
  const token = authRes.idToken;
  console.log('Signed in ✅');

  // 2. Create banner documents
  for (const ad of ADS) {
    const doc = toFirestoreDoc({
      image: ad.image,
      title: ad.title,
      description: ad.description,
      redirect: '',
      isActive: ad.isActive,
      isFeatured: false,
      views: 0,
      clicks: 0,
      startDate: '',
      endDate: '',
    });

    const res = await firestorePost('Banners', doc, token);
    if (res.name) {
      const id = res.name.split('/').pop();
      console.log(`✅ Created banner "${ad.title}" — id: ${id}`);
    } else {
      console.error(`❌ Failed for "${ad.title}":`, JSON.stringify(res, null, 2));
    }
  }

  console.log('\nDone! Open the MediAdmin app → Banners to see them.');
})();

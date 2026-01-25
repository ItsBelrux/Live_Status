import { kv } from '@vercel/kv';

const API_KEY = process.env.API_KEY;
const OFFLINE_THRESHOLD = 15000; // 15 saniye

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET');
  
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
  
  const authKey = req.headers['x-api-key'] || req.query.key;
  if (!authKey || authKey !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const keys = await kv.keys('session:*');
    const sessions = [];
    const now = Date.now();
    
    for (const key of keys) {
      const session = await kv.get(key);
      if (session) {
        // Offline kontrolü
        const isOffline = (now - session.lastPing) > OFFLINE_THRESHOLD;
        session.status = isOffline ? 'offline' : 'online';
        session.lastSeen = new Date(session.lastPing).toLocaleString('tr-TR');
        
        // Süre hesaplama
        const duration = Math.floor((now - session.createdAt) / 1000);
        session.duration = duration;
        
        sessions.push(session);
      }
    }
    
    // Son ping'e göre sırala (en yeni başta)
    sessions.sort((a, b) => b.lastPing - a.lastPing);
    
    return res.status(200).json({
      success: true,
      count: sessions.length,
      online: sessions.filter(s => s.status === 'online').length,
      sessions: sessions
    });
    
  } catch (error) {
    console.error('Sessions Error:', error);
    return res.status(500).json({ error: 'Internal error' });
  }
}


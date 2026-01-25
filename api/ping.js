import { kv } from '@vercel/kv';

const API_KEY = process.env.API_KEY;

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST');
  
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  
  const authKey = req.headers['x-api-key'];
  if (!authKey || authKey !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const { sessionId } = req.body;
    if (!sessionId) return res.status(400).json({ error: 'Session ID required' });

    const session = await kv.get(`session:${sessionId}`);
    if (!session) return res.status(404).json({ error: 'Session not found' });

    // Güncelle
    session.lastPing = Date.now();
    session.status = 'online';
    
    await kv.set(`session:${sessionId}`, session, { ex: 86400 });
    
    return res.status(200).json({ 
      success: true, 
      status: 'online',
      timestamp: Date.now() 
    });
    
  } catch (error) {
    console.error('Ping Error:', error);
    return res.status(500).json({ error: 'Internal error' });
  }
}


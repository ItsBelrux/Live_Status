import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

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

    const sessionData = await redis.get(`session:${sessionId}`);
    if (!sessionData) return res.status(404).json({ error: 'Session not found' });

    const session = typeof sessionData === 'string' ? JSON.parse(sessionData) : sessionData;
    
    session.lastPing = Date.now();
    session.status = 'online';
    
    await redis.set(`session:${sessionId}`, JSON.stringify(session), { ex: 86400 });
    
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

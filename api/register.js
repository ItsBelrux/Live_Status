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
    return res.status(401).json({ error: 'Unauthorized', success: false });
  }

  try {
    const { sessionId, username, displayName, jobId, placeId, totalRap, executor } = req.body;
    
    if (!sessionId || !jobId || !username) {
      return res.status(400).json({ error: 'Missing required fields', success: false });
    }

    const sessionData = {
      sessionId,
      username,
      displayName: displayName || username,
      jobId,
      placeId: placeId || 142823291,
      totalRap: parseInt(totalRap) || 0,
      executor: executor || 'Unknown',
      status: 'online',
      lastPing: Date.now(),
      createdAt: Date.now()
    };

    // Redis'e kaydet (24 saat TTL)
    await redis.set(`session:${sessionId}`, JSON.stringify(sessionData), { ex: 86400 });
    
    // İstatistikleri güncelle
    await redis.incr('stats:total_sessions');
    if (parseInt(totalRap) > 1000) await redis.incr('stats:big_hits');
    
    console.log(`[+] New Session: ${username} | Value: ${totalRap}`);
    return res.status(200).json({ success: true, message: 'Session registered' });
    
  } catch (error) {
    console.error('Register Error:', error);
    return res.status(500).json({ error: 'Internal server error', success: false });
  }
}

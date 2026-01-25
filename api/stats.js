import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

const API_KEY = process.env.API_KEY;

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  
  const authKey = req.headers['x-api-key'] || req.query.key;
  if (!authKey || authKey !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const keys = await redis.keys('session:*');
    let totalValue = 0;
    let maxValue = 0;
    let onlineCount = 0;
    const executors = {};
    const now = Date.now();
    
    for (const key of keys) {
      const data = await redis.get(key);
      if (data) {
        const s = typeof data === 'string' ? JSON.parse(data) : data;
        totalValue += s.totalRap || 0;
        if (s.totalRap > maxValue) maxValue = s.totalRap;
        if ((now - s.lastPing) < 15000) onlineCount++;
        
        executors[s.executor] = (executors[s.executor] || 0) + 1;
      }
    }
    
    const totalSessions = await redis.get('stats:total_sessions') || 0;
    const bigHits = await redis.get('stats:big_hits') || 0;
    
    return res.json({
      success: true,
      stats: {
        totalSessions: keys.length,
        allTimeSessions: parseInt(totalSessions),
        onlineNow: onlineCount,
        totalValue,
        maxValue,
        bigHits: parseInt(bigHits),
        executors
      }
    });
    
  } catch (error) {
    console.error('Stats Error:', error);
    return res.status(500).json({ error: 'Internal error' });
  }
}

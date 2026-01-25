import { kv } from '@vercel/kv';

const API_KEY = process.env.API_KEY;

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  
  const authKey = req.headers['x-api-key'] || req.query.key;
  if (!authKey || authKey !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const keys = await kv.keys('session:*');
    let totalValue = 0;
    let maxValue = 0;
    let onlineCount = 0;
    const executors = {};
    const now = Date.now();
    
    for (const key of keys) {
      const s = await kv.get(key);
      if (s) {
        totalValue += s.totalRap;
        if (s.totalRap > maxValue) maxValue = s.totalRap;
        if ((now - s.lastPing) < 15000) onlineCount++;
        
        executors[s.executor] = (executors[s.executor] || 0) + 1;
      }
    }
    
    const totalSessions = await kv.get('stats:total_sessions') || 0;
    const bigHits = await kv.get('stats:big_hits') || 0;
    
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
    return res.status(500).json({ error: 'Internal error' });
  }
}


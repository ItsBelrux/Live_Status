import { kv } from '@vercel/kv';

const API_KEY = process.env.API_KEY;

export default async function handler(req, res) {
  // CORS ve Method kontrolü
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST');
  
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  
  // Auth kontrolü
  const authKey = req.headers['x-api-key'];
  if (!authKey || authKey !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized', success: false });
  }

  try {
    const { sessionId, vaultId, messageId, channelId, username, displayName, jobId, placeId, totalRap, executor } = req.body;
    
    if (!sessionId || !jobId || !username) {
      return res.status(400).json({ error: 'Missing required fields', success: false });
    }

    const sessionData = {
      sessionId,
      vaultId: vaultId || 'unknown',
      messageId: messageId || '',
      channelId: channelId || '',
      username,
      displayName: displayName || username,
      jobId,
      placeId: placeId || 142823291,
      totalRap: parseInt(totalRap) || 0,
      executor: executor || 'Unknown',
      status: 'online',
      lastPing: Date.now(),
      createdAt: Date.now(),
      ip: req.headers['x-forwarded-for'] || 'unknown'
    };

    // KV'ye kaydet (24 saat TTL)
    await kv.set(`session:${sessionId}`, sessionData, { ex: 86400 });
    
    // İstatistikleri güncelle
    await kv.incr('stats:total_sessions');
    if (parseInt(totalRap) > 1000) await kv.incr('stats:big_hits');
    
    console.log(`[+] New Session: ${username} | Value: ${totalRap}`);
    return res.status(200).json({ success: true, message: 'Session registered' });
    
  } catch (error) {
    console.error('Register Error:', error);
    return res.status(500).json({ error: 'Internal server error', success: false });
  }
}


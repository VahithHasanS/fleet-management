const { io } = require('socket.io-client') || require('socket.io-client/build/index.js');
const http = require('http');
function post(path, body, token) {
  return new Promise((res, rej) => {
    const data = JSON.stringify(body);
    const req = http.request({host:'localhost',port:3000,path,method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})}}, r => {
      let b=''; r.on('data',c=>b+=c); r.on('end',()=>{ try{res(JSON.parse(b))}catch(e){res(b)} });
    });
    req.on('error',rej); req.write(data); req.end();
  });
}
(async () => {
  const login = await post('/api/v1/auth/login', {email:'driver@ghost.local', password:'ghost123'});
  if (!login.accessToken) { console.log('LOGIN FAIL', login); process.exit(1); }
  console.log('driver login ok, driverId=', login.user.driverId, 'tenant=', login.user.tenantId);
  // find assigned vehicle
  const vehicles = await new Promise((res,rej)=>{
    http.get({host:'localhost',port:3000,path:'/api/v1/tenants/'+login.user.tenantId+'/vehicles',headers:{Authorization:'Bearer '+login.accessToken}},r=>{let b='';r.on('data',c=>b+=c);r.on('end',()=>res(JSON.parse(b)))}).on('error',rej);
  });
  const mine = vehicles.find(v => String(v.driverId || v.driver?.id || '') === String(login.user.driverId));
  if (!mine) { console.log('ASSIGNED VEHICLE NOT FOUND', vehicles.length); process.exit(1); }
  console.log('vehicle:', mine.name, mine.plate, mine._id);
  const socket = io('http://localhost:3000', {path:'/ws', transports:['websocket'], auth:{token: login.accessToken}});
  socket.on('connect', async () => {
    console.log('ws connected');
    socket.emit('live:subscribe', {tenantId: login.user.tenantId});
    const now = Date.now();
    const batch = {
      schemaVersion:'1.2', vehicleId: mine.id || mine._id, tripId:'e2e-driver-trip-'+Date.now(), seq: 1,
      batchStart: new Date(now-5000).toISOString(),
      points: [
        {t:0, lat:11.0168, lon:76.9558, spd:42, hdg:90, acc:-0.52, la:0, conf:0.97},
        {t:1, lat:11.0169, lon:76.9560, spd:55, hdg:91, acc:0.6, la:0.05, conf:0.97},
        {t:2, lat:11.0170, lon:76.9562, spd:61, hdg:90, acc:0.1, la:0.4, conf:0.97},
        {t:3, lat:11.0171, lon:76.9564, spd:58, hdg:89, acc:-0.1, la:0.02, conf:0.97},
        {t:4, lat:11.0172, lon:76.9566, spd:44, hdg:90, acc:-0.2, la:0.01, conf:0.97},
      ],
      events: [{type:'sos', t:4, magnitude:1, conf:1, detail:'E2E driver SOS'}],
    };
    socket.timeout(8000).emit('telemetry', batch, (err, ack) => {
      if (err) { console.log('ACK ERR', err.message); process.exit(1); }
      console.log('ingest ack:', JSON.stringify(ack));
    });
  });
  socket.on('live:sos', (p) => console.log('LIVE SOS PUSH:', JSON.stringify(p).slice(0,160)));
  socket.on('connect_error', e => console.log('ws error', e.message));
  setTimeout(async () => {
    const alerts = await new Promise((res,rej)=>{
      http.get({host:'localhost',port:3000,path:'/api/v1/tenants/'+login.user.tenantId+'/alerts?limit=3',headers:{Authorization:'Bearer '+login.accessToken}},r=>{let b='';r.on('data',c=>b+=c);r.on('end',()=>res(JSON.parse(b)))}).on('error',rej);
    });
    console.log('recent alerts:', JSON.stringify(alerts.slice? alerts.slice(0,2): alerts).slice(0,300));
    process.exit(0);
  }, 10000);
})().catch(e => { console.error('FATAL', e); process.exit(1); });

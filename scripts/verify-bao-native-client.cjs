const {resolve}=require('node:path');
const {writeFileSync}=require('node:fs');
const {execFileSync}=require('node:child_process');
const {createHash}=require('node:crypto');
const root=resolve(__dirname,'..');
const adb='D:/Android/SDK/platform-tools/adb.exe';
const serial='emulator-5558';
const [mode,label,expectedAlias,foreignAlias]=process.argv.slice(2);
if(!['client','role'].includes(mode)||!/^[a-z0-9-]{1,50}$/.test(label??''))throw Error('Invalid probe');
const alias=u=>'uid-sha256:'+createHash('sha256').update(u).digest('hex').slice(0,16);
const allowed=new Set(['uid-sha256:4a7de057a03aa476','uid-sha256:564b131109a53e16','uid-sha256:e82554223119b7ff']);
let forward;
(async()=>{
 const base=resolve(root,'firebase/node_modules/firebase-tools/lib');
 require(resolve(base,'logger')).logger.silent=true;
 const firebase=require(resolve(base,'index'));
 const {Client}=require(resolve(base,'apiv2'));
 await firebase.projects.list({project:'beewise-lab-3',nonInteractive:true});
 let expectedUid,foreignUid;
 if(mode==='client'){
  if(!allowed.has(expectedAlias)||!allowed.has(foreignAlias)||expectedAlias===foreignAlias)throw Error('Unauthorized test identity');
  const api=new Client({urlPrefix:'https://identitytoolkit.googleapis.com',apiVersion:'v1'});
  const {body}=await api.get('/projects/beewise-lab-3/accounts:batchGet',{queryParams:{maxResults:100,fields:'users(localId)'},timeout:30000});
  for(const u of body.users??[]){if(alias(u.localId)===expectedAlias)expectedUid=u.localId;if(alias(u.localId)===foreignAlias)foreignUid=u.localId;}
  if(!expectedUid||!foreignUid)throw Error('Authorized identity missing');
 }
 const run=(...a)=>execFileSync(adb,['-s',serial,...a],{encoding:'utf8',timeout:30000,windowsHide:true});
 const pid=run('shell','pidof','com.beewise.beewise').trim();
 if(!/^\d+$/.test(pid))throw Error('App PID absent');
 const logs=run('logcat','-d','--pid',pid,'-t','2000');
 const uris=[...logs.matchAll(/Dart VM service is listening on (http:\/\/127\.0\.0\.1:(\d+)\/[^\s]+)/g)];
 if(!uris.length)throw Error('VM URI unavailable');
 const [,uri,port]=uris.at(-1);
 forward=run('forward','tcp:0','tcp:'+port).trim();
 const url=uri.replace('http:','ws:').replace(':'+port+'/',':'+forward+'/').replace(/\/?$/,'/ws');
 const ws=new WebSocket(url);let next=0;const pending=new Map();
 ws.onmessage=e=>{const r=JSON.parse(e.data);const p=pending.get(r.id);if(!p)return;pending.delete(r.id);r.error?p.reject(Error('VM RPC rejected')):p.resolve(r.result);};
 await new Promise((res,rej)=>{ws.onopen=res;ws.onerror=()=>rej(Error('VM connection failed'));setTimeout(()=>rej(Error('VM connection timeout')),10000).unref();});
 const rpc=(method,params={})=>new Promise((res,rej)=>{const id=++next;const timer=setTimeout(()=>{pending.delete(id);rej(Error('Probe timeout'));},60000);pending.set(id,{resolve:v=>{clearTimeout(timer);res(v)},reject:e=>{clearTimeout(timer);rej(e)}});ws.send(JSON.stringify({jsonrpc:'2.0',id,method,params}));});
 try{
  const vm=await rpc('getVM');let target;
  for(const i of vm.isolates??[]){const info=await rpc('getIsolate',{isolateId:i.id});if(info.extensionRPCs?.includes('ext.beewise.clientReadCheck')){target=i.id;break;}}
  if(!target)throw Error('Probe entrypoint not running');
  const result=await rpc(mode==='client'?'ext.beewise.clientReadCheck':'ext.beewise.roleRead',{isolateId:target,...(mode==='client'?{expectedUid,foreignUid}:{})});
  const receipt={timestampUtc:new Date().toISOString(),sourceSha:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),device:serial,label,mode,expectedAccountAlias:expectedAlias??null,foreignAccountAlias:foreignAlias??null,result,credentialOrDocumentDataExported:false};
  writeFileSync(resolve(root,`evidence/cloud/reliability-${label}.json`),JSON.stringify(receipt,null,2)+'\n');
  console.log(JSON.stringify(receipt));
 }finally{ws.close();}
})().catch(()=>{console.log(JSON.stringify({status:'BLOCKED',label,reason:'Native client probe could not complete; no raw SDK error, identity or connection secret emitted'}));process.exitCode=1;}).finally(()=>{
 if(forward)try{execFileSync(adb,['-s',serial,'forward','--remove','tcp:'+forward],{windowsHide:true,stdio:'ignore'});}catch{}
});

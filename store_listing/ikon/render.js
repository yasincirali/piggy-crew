const { chromium } = require('playwright');
const fs=require('fs');
(async()=>{
 const b=await chromium.launch({executablePath:'process.env.CHROME_PATH || undefined'}).catch(async()=>chromium.launch());
 const p=await b.newPage({viewport:{width:1024,height:1024}});
 for(const [n,transp] of [['ikon',false],['on_plan',true],['arka_plan',false],['tek_renk',true]]){
  const s=fs.readFileSync(n+'.svg','utf8');
  await p.setContent(`<html><body style="margin:0;background:transparent">${s}</body></html>`);
  await p.locator('svg').screenshot({path:n+'.png',omitBackground:transp});
 }
 await b.close();
})();

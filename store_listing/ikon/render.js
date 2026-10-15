// Kaynak SVG'leri 1024 px PNG'ye çevirir. Saydam katmanlar (ön plan, tek renk) alfa ile çıkar.
const { chromium } = require('playwright'); const fs=require('fs');
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1024,height:1024}});
for(const [n,t] of [['ikon',false],['on_plan',true],['arka_plan',false],['tek_renk',true]]){
 await p.setContent(`<body style="margin:0;background:transparent">${fs.readFileSync(n+'.svg','utf8')}</body>`);
 await p.locator('svg').screenshot({path:n+'.png',omitBackground:t});}
await b.close();})();

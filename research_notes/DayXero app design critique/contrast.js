// WCAG 2.x contrast for every DayXero ground (ink + muted, light + dark), plus key accent/button pairs.
const NAVY='#1E1A3A',CREAM='#FFF8EE',PLUM='#241433';
const grounds={coral:{light:'#FF7A55',dark:PLUM,inkLight:NAVY,inkDark:CREAM,mutedLight:'#3B1A24',mutedDark:'#E0C8E8'},
apricot:{light:'#FFC38A',dark:PLUM,inkLight:NAVY,inkDark:CREAM,mutedLight:'#4A2A1A',mutedDark:'#E0C8E8'},
lilac:{light:'#D9CCFF',dark:'#1C1640',inkLight:NAVY,inkDark:CREAM,mutedLight:'#4A3E7A',mutedDark:'#C9BFF2'},
mint:{light:'#9FE3BC',dark:'#0F2A22',inkLight:NAVY,inkDark:CREAM,mutedLight:'#24493A',mutedDark:'#A9D9C0'},
ocean:{light:'#2A52DB',dark:'#0B1A4A',inkLight:CREAM,inkDark:CREAM,mutedLight:'#E3EAFF',mutedDark:'#B9C9FF'},
sky:{light:'#9CCBFF',dark:'#0F2550',inkLight:NAVY,inkDark:CREAM,mutedLight:'#24406E',mutedDark:'#B9D6FF'},
violet:{light:'#4A3596',dark:'#140E3A',inkLight:CREAM,inkDark:CREAM,mutedLight:'#D2C8FF',mutedDark:'#B8B3D9'},
sun:{light:'#FFD966',dark:PLUM,inkLight:NAVY,inkDark:CREAM,mutedLight:'#5A4A10',mutedDark:'#E0C8E8'},
reading:{light:'#FBF7F1',dark:'#0E0B2B',inkLight:NAVY,inkDark:CREAM,mutedLight:'#5E5975',mutedDark:'#B8B3D9'},
lime:{light:'#C1F07A',dark:'#0F2A22',inkLight:NAVY,inkDark:CREAM,mutedLight:'#33470F',mutedDark:'#A9D9C0'},
mist:{light:'#C9D6FF',dark:'#0B1A4A',inkLight:NAVY,inkDark:CREAM,mutedLight:'#24406E',mutedDark:'#B9C9FF'},
periwinkle:{light:'#B4C4FF',dark:'#140E3A',inkLight:NAVY,inkDark:CREAM,mutedLight:'#24406E',mutedDark:'#B8B3D9'}};
function rgb(h){h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.slice(i,i+2),16)/255);}
function lum(h){return rgb(h).map(c=>c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4)).reduce((a,c,i)=>a+c*[0.2126,0.7152,0.0722][i],0);}
function cr(a,b){const [l1,l2]=[lum(a),lum(b)].sort((x,y)=>y-x);return ((l1+0.05)/(l2+0.05));}
function blend(fg,alpha,bg){const f=rgb(fg),b=rgb(bg);return '#'+f.map((c,i)=>Math.round((c*alpha+b[i]*(1-alpha))*255).toString(16).padStart(2,'0')).join('');}
const f=x=>x.toFixed(2);
console.log('ground | light bg | ink/light | muted/light | dark bg | ink/dark | muted/dark');
for(const g in grounds){const s=grounds[g];
 console.log(`${g} | ${s.light} | ${f(cr(s.inkLight,s.light))} | ${f(cr(s.mutedLight,s.light))} | ${s.dark} | ${f(cr(s.inkDark,s.dark))} | ${f(cr(s.mutedDark,s.dark))}`);}
console.log('\n-- cards on colour (cream 70% over ground), ink on card:');
for(const g of ['coral','apricot','lilac','mint','sky','sun','lime','mist','periwinkle']){const s=grounds[g];const card=blend(CREAM,0.70,s.light);console.log(`${g} card ${card}: ink ${f(cr(NAVY,card))}, muted ${f(cr(s.mutedLight,card))}, card-vs-ground ${f(cr(card,s.light))}`);}
console.log('\n-- navy 20% card on ocean/violet:');
for(const g of ['ocean','violet']){const s=grounds[g];const card=blend(NAVY,0.20,s.light);console.log(`${g} card ${card}: cream ${f(cr(CREAM,card))}, muted ${f(cr(s.mutedLight,card))}, card-vs-ground ${f(cr(card,s.light))}`);}
console.log('\n-- dark mode cards (white 10% over dark ground):');
for(const g in grounds){const s=grounds[g];const card=blend('#FFFFFF',0.10,s.dark);console.log(`${g} dark card ${card}: cream ${f(cr(CREAM,card))}, muted ${f(cr(s.mutedDark,card))}, card-vs-ground ${f(cr(card,s.dark))}`);}
console.log('\n-- accents:');
const pairs=[['green #0F6E43 on reading',' #0F6E43','#FBF7F1'],['green dark #2FD08A on reading dark','#2FD08A','#0E0B2B'],['coral #FF7A55 on reading (mark/accent)','#FF7A55','#FBF7F1'],['coral on cream card','#FF7A55',CREAM],['cream on coral','#FFF8EE','#FF7A55'],['cream on apricot','#FFF8EE','#FFC38A'],['apricot button text plum','#241433','#FFC38A'],['ocean on reading','#2A52DB','#FBF7F1'],['ocean on cream','#2A52DB',CREAM],['ocean dark #7FB0FF on #0E0B2B','#7FB0FF','#0E0B2B'],['sun #FFD966 on ocean (mark)','#FFD966','#2A52DB'],['sun on violet (mark)','#FFD966','#4A3596'],['cream on sun','#FFF8EE','#FFD966'],['navy on sun','#1E1A3A','#FFD966'],['ocean secondary #1D3A9E vs ocean','#1D3A9E','#2A52DB'],['cream on #1D3A9E','#FFF8EE','#1D3A9E'],['surface #F1EBE2 vs reading','#F1EBE2','#FBF7F1'],['raised dark #2A255F vs reading dark','#2A255F','#0E0B2B'],['white vs reading light (raised)','#FFFFFF','#FBF7F1'],['muted reading #5E5975 on white','#5E5975','#FFFFFF'],['muted reading #5E5975 on surface #F1EBE2','#5E5975','#F1EBE2'],['Glim violet #6B4FD8 on violet','#6B4FD8','#4A3596'],['coral vs apricot','#FF7A55','#FFC38A'],['coral vs sun','#FF7A55','#FFD966'],['mist vs periwinkle','#C9D6FF','#B4C4FF'],['sky vs mist','#9CCBFF','#C9D6FF'],['mint vs lime','#9FE3BC','#C1F07A'],['navy on coral','#1E1A3A','#FF7A55'],['#3B1A24 muted on coral','#3B1A24','#FF7A55']];
for(const [n,a,b] of pairs)console.log(`${n}: ${f(cr(a.trim(),b))}`);

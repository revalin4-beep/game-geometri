<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Game Geometri Platformer – Kelas 8</title>
  <style>
    :root{
      --bg:#a3d5ff; --platform:#8bd17c; --spike:#cc3333; --player:#264653; --star:#f1c40f; --flag:#ff7f50; --doorC:#555; --doorO:#2ecc71; --text:#111;
    }
    html,body{height:100%;margin:0;font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Arial}
    body{background:#f1f5f9;display:flex;flex-direction:column;align-items:center;gap:12px;padding:16px}
    h1{margin:6px 0;font-size:22px}
    .card{background:#fff;border:1px solid #e2e8f0;border-radius:14px;box-shadow:0 6px 16px rgba(0,0,0,.07)}
    .wrap{padding:10px}
    #game{display:block;border-radius:12px;border:1px solid #e2e8f0;background:var(--bg)}
    .row{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px;max-width:960px;width:100%}
    .p{padding:12px;color:#334155;font-size:14px}
    .small{font-size:12px;color:#64748b}
    /* Modal */
    .modal{position:fixed;inset:0;background:rgba(0,0,0,.5);display:none;align-items:center;justify-content:center;padding:16px;z-index:5}
    .modal>div{background:#fff;border-radius:14px;max-width:640px;width:100%;padding:16px;border:1px solid #e2e8f0}
    .btn{display:block;width:100%;text-align:left;border:1px solid #e2e8f0;border-radius:10px;background:#fff;padding:10px 12px;margin:6px 0;cursor:pointer}
    .btn:hover{background:#f8fafc}
    .actions{display:flex;gap:8px;justify-content:flex-end;margin-top:10px}
    .primary{background:#0f172a;color:#fff;border-color:#0f172a}
    .hud{position:absolute;left:0;top:0;width:100%;height:40px;background:rgba(255,255,255,.6);display:flex;align-items:center;gap:24px;padding:0 12px;color:#111}
    .footermsg{position:absolute;left:0;right:0;bottom:0;height:36px;background:rgba(0,0,0,.6);color:#fff;display:flex;align-items:center;padding:0 12px}
    .stage{position:relative}
  </style>
</head>
<body>
  <h1>Game Edukasi Geometri – Platformer (HTML)</h1>
  <div class="small">Kontrol: ← → bergerak, Spasi lompat, P pause, R reset.</div>

  <div class="card wrap stage">
    <div class="hud" id="hud"></div>
    <canvas id="game" width="960" height="540"></canvas>
    <div class="footermsg" id="fmsg"></div>
  </div>

  <div class="row">
    <div class="card p">
      <b>Petunjuk</b>
      <ul>
        <li>Kumpulkan bintang (+10).</li>
        <li>Sentuh bendera untuk membuka kuis. Jawab benar (+20) untuk membuka gerbang.</li>
        <li>Hindari duri atau jatuh: nyawa berkurang.</li>
      </ul>
    </div>
    <div class="card p">
      <b>Untuk Guru</b>
      <p>Edit bank soal pada variabel <code>LEVELS</code> di dalam file ini (keliling & luas, segitiga, jajargenjang, trapesium, belah ketupat, lingkaran).</p>
    </div>
    <div class="card p small">
      <b>Tips</b>
      <p>Jika game tidak merespons tombol, klik area kanvas dulu.</p>
    </div>
  </div>

  <!-- Modal Kuis -->
  <div class="modal" id="quizModal">
    <div>
      <h3 style="margin:0 0 8px;font-size:18px">Kuis Geometri</h3>
      <p id="quizPrompt" style="margin:0 0 10px;color:#334155"></p>
      <div id="quizChoices"></div>
      <details style="margin-top:8px">
        <summary>Butuh bantuan? Lihat penjelasan</summary>
        <div id="quizExplain" class="small" style="margin-top:6px;background:#f1f5f9;border:1px solid #e2e8f0;border-radius:10px;padding:8px"></div>
      </details>
      <div class="actions">
        <button class="btn primary" id="quizClose">Tutup</button>
      </div>
    </div>
  </div>

  <script>
    // ========= Util =========
    function shuffle(arr){const a=[...arr];for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a}
    function aabb(a,b){return a.x<b.x+b.w && a.x+a.w>b.x && a.y<b.y+b.h && a.y+a.h>b.y}
    
    // ========= Level Data =========
    const LEVELS=[
      { name:"Level 1 – Persegi Panjang",
        platforms:[{x:0,y:500,w:960,h:40},{x:100,y:420,w:180,h:20},{x:340,y:360,w:160,h:20},{x:580,y:300,w:200,h:20}],
        spikes:[{x:280,y:500,w:60,h:40}],
        stars:[{x:150,y:380},{x:380,y:320},{x:640,y:260}],
        start:{x:40,y:440}, quizFlag:{x:780,y:260,w:16,h:40}, exitDoor:{x:900,y:460,w:24,h:40},
        quiz:{
          prompt:"Sebuah persegi panjang memiliki panjang 12 cm dan lebar 7 cm. Berapakah kelilingnya?",
          choices:[{text:"38 cm",correct:true},{text:"84 cm",correct:false},{text:"26 cm",correct:false},{text:"96 cm",correct:false}],
          explanation:"Keliling persegi panjang = 2 × (p + l) = 2 × (12 + 7) = 38 cm."
        }
      },
      { name:"Level 2 – Segitiga",
        platforms:[{x:0,y:500,w:960,h:40},{x:120,y:440,w:140,h:20},{x:300,y:380,w:160,h:20},{x:520,y:330,w:180,h:20},{x:760,y:290,w:140,h:20}],
        spikes:[{x:460,y:500,w:80,h:40},{x:700,y:500,w:60,h:40}],
        stars:[{x:170,y:400},{x:360,y:340},{x:800,y:250}],
        start:{x:40,y:440}, quizFlag:{x:780,y:250,w:16,h:40}, exitDoor:{x:900,y:460,w:24,h:40},
        quiz:{
          prompt:"Sebuah segitiga memiliki alas 10 cm dan tinggi 8 cm. Berapakah luas segitiga tersebut?",
          choices:[{text:"40 cm²",correct:true},{text:"80 cm²",correct:false},{text:"18 cm²",correct:false},{text:"28 cm²",correct:false}],
          explanation:"Luas segitiga = 1/2 × alas × tinggi = 1/2 × 10 × 8 = 40 cm²."
        }
      },
      { name:"Level 3 – Jajar Genjang & Sudut",
        platforms:[{x:0,y:500,w:960,h:40},{x:160,y:430,w:140,h:20},{x:340,y:370,w:160,h:20},{x:560,y:320,w:160,h:20},{x:760,y:280,w:160,h:20}],
        spikes:[{x:250,y:500,w:60,h:40},{x:480,y:500,w:60,h:40},{x:720,y:500,w:60,h:40}],
        stars:[{x:200,y:390},{x:420,y:330},{x:780,y:240}],
        start:{x:40,y:440}, quizFlag:{x:800,y:240,w:16,h:40}, exitDoor:{x:900,y:460,w:24,h:40},
        quiz:{
          prompt:"Jajar genjang memiliki alas 15 cm dan tinggi 6 cm. Berapakah luasnya? (Tambahan: jumlah sudut dalam segiempat berapa derajat?)",
          choices:shuffle([{text:"90 cm² dan 360°",correct:true},{text:"90 cm² dan 180°",correct:false},{text:"45 cm² dan 360°",correct:false},{text:"96 cm² dan 270°",correct:false}]),
          explanation:"Luas = alas × tinggi = 15 × 6 = 90 cm². Jumlah sudut dalam segiempat = 360°."
        }
      },
    ];

    // ========= State =========
    const W=960,H=540;
    const canvas=document.getElementById('game');
    const ctx=canvas.getContext('2d');
    const hud=document.getElementById('hud');
    const fmsg=document.getElementById('fmsg');

    const quizModal=document.getElementById('quizModal');
    const quizPrompt=document.getElementById('quizPrompt');
    const quizChoices=document.getElementById('quizChoices');
    const quizExplain=document.getElementById('quizExplain');
    const quizClose=document.getElementById('quizClose');

    let levelIndex=0, score=0, lives=3, paused=false, quizOpen=false, quizUnlocked=false;
    let player={x:0,y:0,vx:0,vy:0,onGround:false};
    let stars=[];
    let keys={left:false,right:false,jump:false};

    function loadLevel(i){
      const lv=LEVELS[i];
      player={x:lv.start.x,y:lv.start.y,vx:0,vy:0,onGround:false};
      stars=lv.stars.map(s=>({...s,collected:false}));
      quizUnlocked=false; paused=false; quizOpen=false;
      setMsg(lv.name+" – Sentuh bendera untuk membuka kuis.");
    }

    function setMsg(m){ fmsg.textContent=m; }
    function setHUD(){
      hud.textContent=`${LEVELS[levelIndex].name}    Skor: ${score}    Nyawa: ${lives}    P: Pause`;
    }

    loadLevel(levelIndex);
    setHUD();

    // ========= Input =========
    window.addEventListener('keydown',e=>{
      if(e.code==='ArrowLeft'||e.code==='KeyA') keys.left=true;
      if(e.code==='ArrowRight'||e.code==='KeyD') keys.right=true;
      if(e.code==='Space'||e.code==='ArrowUp'||e.code==='KeyW') keys.jump=true;
      if(e.code==='KeyP'){paused=!paused}
      if(e.code==='KeyR'){levelIndex=0;score=0;lives=3;loadLevel(0)}
    });
    window.addEventListener('keyup',e=>{
      if(e.code==='ArrowLeft'||e.code==='KeyA') keys.left=false;
      if(e.code==='ArrowRight'||e.code==='KeyD') keys.right=false;
      if(e.code==='Space'||e.code==='ArrowUp'||e.code==='KeyW') keys.jump=false;
    });

    // ========= Quiz =========
    function openQuiz(){
      const lv=LEVELS[levelIndex];
      quizPrompt.textContent=lv.quiz.prompt;
      quizExplain.textContent=lv.quiz.explanation;
      quizChoices.innerHTML='';
      const choices=shuffle(lv.quiz.choices);
      choices.forEach((c)=>{
        const b=document.createElement('button');
        b.className='btn';
        b.textContent=c.text;
        b.onclick=()=>submitAnswer(c);
        quizChoices.appendChild(b);
      });
      quizModal.style.display='flex';
      quizOpen=true; paused=true;
    }
    function closeQuiz(){ quizModal.style.display='none'; quizOpen=false; paused=false; }
    quizClose.onclick=closeQuiz;

    function submitAnswer(choice){
      if(choice.correct){
        setMsg('Benar! Gerbang terbuka. Pergi ke gerbang untuk lanjut.');
        quizUnlocked=true; score+=20;
      }else{
        setMsg('Kurang tepat. Coba lagi – hati-hati rintangan!');
        lives=Math.max(0,lives-1);
      }
      closeQuiz();
    }

    // ========= Game Loop =========
    let last=performance.now();
    function loop(now){
      const dt=Math.min(0.033,(now-last)/1000); last=now;
      if(!paused && !quizOpen) update(dt);
      render();
      requestAnimationFrame(loop);
    }
    requestAnimationFrame(loop);

    function resetPlayer(){
      const lv=LEVELS[levelIndex];
      player.x=lv.start.x; player.y=lv.start.y; player.vx=0; player.vy=0; player.onGround=false;
    }

    function update(dt){
      const lv=LEVELS[levelIndex];
      const acc=1200, maxSpeed=220, friction=900, gravity=1800, jumpSpeed=560;
      if(keys.left) player.vx -= acc*dt;
      if(keys.right) player.vx += acc*dt;
      if(!keys.left && !keys.right){
        if(player.vx>0) player.vx=Math.max(0,player.vx-friction*dt);
        else if(player.vx<0) player.vx=Math.min(0,player.vx+friction*dt);
      }
      player.vx=Math.max(-maxSpeed,Math.min(maxSpeed,player.vx));
      if(keys.jump && player.onGround){ player.vy=-jumpSpeed; player.onGround=false; }
      player.vy += gravity*dt;

      let nx=player.x + player.vx*dt;
      let ny=player.y + player.vy*dt;
      player.onGround=false;

      // Platform collisions
      for(const plat of lv.platforms){
        // vertical
        const vb={x:player.x,y:ny,w:24,h:36};
        if(aabb(vb,plat)){
          if(player.vy>0){ ny=plat.y-36; player.vy=0; player.onGround=true; }
          else if(player.vy<0){ ny=plat.y+plat.h; player.vy=0; }
        }
        // horizontal
        const hb={x:nx,y:ny,w:24,h:36};
        if(aabb(hb,plat)){
          if(player.vx>0) nx=plat.x-24; else if(player.vx<0) nx=plat.x+plat.w; player.vx=0;
        }
      }

      // World bounds
      if(nx<0){nx=0;player.vx=0}
      if(nx+24>W){nx=W-24;player.vx=0}
      if(ny+36>H){
        lives=(l=>{const n=l-1; if(n<=0){setMsg('Game Over! Tekan R untuk mengulang.'); paused=true;} return Math.max(0,n)})(lives);
        resetPlayer();
        setHUD();
        return;
      }

      player.x=nx; player.y=ny;

      // Collect stars
      for(const s of stars){
        if(!s.collected){
          const d=Math.hypot((player.x+12)-s.x,(player.y+18)-s.y);
          if(d<24){ s.collected=true; score+=10; }
        }
      }

      // Spikes
      for(const sp of lv.spikes){
        const pb={x:player.x,y:player.y,w:24,h:36};
        if(aabb(pb,sp)){
          lives=Math.max(0,lives-1); resetPlayer(); return;
        }
      }

      // Quiz flag
      const flagBox={x:lv.quizFlag.x-8,y:lv.quizFlag.y-8,w:lv.quizFlag.w+16,h:lv.quizFlag.h+16};
      if(aabb({x:player.x,y:player.y,w:24,h:36},flagBox)){
        if(!quizUnlocked) openQuiz();
      }

      // Exit door
      const door=lv.exitDoor; const doorB={x:door.x,y:door.y,w:door.w,h:door.h};
      if(aabb({x:player.x,y:player.y,w:24,h:36},doorB)){
        if(quizUnlocked){
          if(levelIndex<LEVELS.length-1){ levelIndex++; loadLevel(levelIndex); setMsg('Level berikutnya!'); }
          else { setMsg('Selamat! Semua level selesai.'); paused=true; }
        }
      }

      setHUD();
    }

    function drawStar(cx,cy,spikes,outerR,innerR){
      let rot=Math.PI/2*3; let x=cx, y=cy; const step=Math.PI/spikes;
      ctx.beginPath(); ctx.moveTo(cx,cy-outerR);
      for(let i=0;i<spikes;i++){
        x=cx+Math.cos(rot)*outerR; y=cy+Math.sin(rot)*outerR; ctx.lineTo(x,y); rot+=step;
        x=cx+Math.cos(rot)*innerR; y=cy+Math.sin(rot)*innerR; ctx.lineTo(x,y); rot+=step;
      }
      ctx.lineTo(cx,cy-outerR); ctx.closePath(); ctx.fillStyle= getComputedStyle(document.documentElement).getPropertyValue('--star')||'#f1c40f'; ctx.fill();
    }

    function render(){
      const lv=LEVELS[levelIndex];
      // bg
      ctx.fillStyle=getComputedStyle(document.documentElement).getPropertyValue('--bg')||'#a3d5ff';
      ctx.fillRect(0,0,W,H);
      // HUD text handled by DOM

      // Platforms
      ctx.fillStyle=getComputedStyle(document.documentElement).getPropertyValue('--platform')||'#8bd17c';
      for(const p of lv.platforms){ ctx.fillRect(p.x,p.y,p.w,p.h); }

      // Spikes (triangles)
      ctx.fillStyle=getComputedStyle(document.documentElement).getPropertyValue('--spike')||'#cc3333';
      for(const sp of lv.spikes){
        const n=Math.max(1,Math.floor(sp.w/12));
        for(let i=0;i<n;i++){
          const x0=sp.x+(i*sp.w)/n;
          ctx.beginPath();
          ctx.moveTo(x0,sp.y+sp.h);
          ctx.lineTo(x0+sp.w/n/2,sp.y);
          ctx.lineTo(x0+sp.w/n,sp.y+sp.h);
          ctx.closePath(); ctx.fill();
        }
      }

      // Stars
      for(const s of stars){ if(s.collected) continue; drawStar(s.x,s.y,5,10,4); }

      // Flag
      ctx.fillStyle=getComputedStyle(document.documentElement).getPropertyValue('--flag')||'#ff7f50';
      ctx.fillRect(lv.quizFlag.x, lv.quizFlag.y - lv.quizFlag.h, 4, lv.quizFlag.h);
      ctx.fillRect(lv.quizFlag.x + 4, lv.quizFlag.y - lv.quizFlag.h, 12, 10);

      // Door
      const doorColor=quizUnlocked ? (getComputedStyle(document.documentElement).getPropertyValue('--doorO')||'#2ecc71') : (getComputedStyle(document.documentElement).getPropertyValue('--doorC')||'#555');
      ctx.fillStyle=doorColor; ctx.fillRect(lv.exitDoor.x, lv.exitDoor.y, lv.exitDoor.w, lv.exitDoor.h);

      // Player
      ctx.fillStyle=getComputedStyle(document.documentElement).getPropertyValue('--player')||'#264653';
      ctx.fillRect(player.x,player.y,24,36);
    }
  </script>
</body>
</html>

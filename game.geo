<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
  <title>Game Geometri Platformer – Mobile</title>
  <style>
    :root{
      --bg:#a3d5ff; --ground:#7c4d2a; --platform:#8bd17c; --spike:#cc3333; --player:#264653; --star:#f1c40f; --flag:#ff7f50; --doorC:#555; --doorO:#2ecc71; --text:#111;
    }
    *{box-sizing:border-box}
    html,body{margin:0;height:100%;background:#eef5ff;font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto}
    .wrap{display:flex;flex-direction:column;align-items:center;gap:10px;padding:10px;min-height:100%}
    h1{font-size:18px;margin:8px 0 0}
    p.tip{margin:0;color:#334155;font-size:12px;text-align:center}

    .stage{background:white;border:1px solid #e2e8f0;border-radius:14px;box-shadow:0 6px 20px rgba(2,6,23,.06);padding:8px}
    canvas{display:block;border-radius:12px;width:100%;height:auto;touch-action:none;background:var(--bg)}

    .hud{display:grid;grid-template-columns:1fr 1fr;gap:8px;width:min(960px,100%)}
    .card{background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:10px;box-shadow:0 4px 14px rgba(2,6,23,.05)}
    .card h3{margin:0 0 6px;font-size:14px}
    .card p, .card li{font-size:12px;color:#475569}

    /* On-screen controls */
    .controls{position:fixed;inset:auto 0 10px 0;display:flex;justify-content:center;gap:10px;pointer-events:auto}
    .btn{padding:14px 16px;border:none;border-radius:18px;background:#0f172a;color:#fff;font-size:16px;box-shadow:0 6px 14px rgba(2,6,23,.2);opacity:.92}
    .btn:active{transform:scale(.97)}
    .btn.small{padding:12px 14px;font-size:14px}

    /* Quiz modal */
    .modal{position:fixed;inset:0;background:rgba(0,0,0,.5);display:none;align-items:center;justify-content:center;padding:16px}
    .modal .box{background:#fff;border-radius:14px;max-width:640px;width:100%;padding:16px;border:1px solid #e2e8f0}
    .modal h2{margin:0 0 8px;font-size:18px}
    .modal p{margin:0 0 12px;color:#334155}
    .opt{display:block;width:100%;text-align:left;margin:6px 0;padding:10px 12px;border:1px solid #e2e8f0;border-radius:10px;background:#f8fafc}
    .opt:active{transform:scale(.99)}
    .note{font-size:12px;color:#64748b}

    /* Prevent iOS Safari zoom on double tap */
    * { touch-action: manipulation; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Game Edukasi Geometri – Platformer (Mobile)</h1>
    <p class="tip">Kontrol: tombol layar (◀ ▶ ⤒), atau geser di atas kanvas untuk bergerak & tap dua jari untuk lompat. P untuk pause, R untuk reset (jika ada keyboard).</p>

    <div class="stage">
      <canvas id="game" width="960" height="540"></canvas>
    </div>

    <div class="hud">
      <div class="card">
        <h3>Level</h3>
        <p id="levelName">Level 1</p>
      </div>
      <div class="card">
        <h3>Petunjuk</h3>
        <ul style="margin:0 0 0 18px">
          <li>Ambil bintang untuk skor (+10).</li>
          <li>Sentuh bendera untuk kuis; jawab benar membuka gerbang (+20).</li>
          <li>Hindari duri dan jangan jatuh.</li>
        </ul>
      </div>
    </div>
  </div>

  <!-- On-screen controls -->
  <div class="controls" id="controls">
    <button class="btn" id="leftBtn">◀</button>
    <button class="btn" id="jumpBtn">⤒ Lompat</button>
    <button class="btn" id="rightBtn">▶</button>
    <button class="btn small" id="pauseBtn">⏸</button>
    <button class="btn small" id="resetBtn">↺</button>
  </div>

  <!-- Quiz Modal -->
  <div class="modal" id="quizModal" role="dialog" aria-modal="true">
    <div class="box">
      <h2>Kuis Geometri</h2>
      <p id="qText">Pertanyaan…</p>
      <div id="qOpts"></div>
      <details class="note"><summary>Butuh bantuan?</summary>
        <div id="qExp" style="margin-top:8px;background:#f1f5f9;padding:10px;border-radius:8px"></div>
      </details>
      <div style="text-align:right;margin-top:10px">
        <button class="btn small" id="closeQuiz">Tutup</button>
      </div>
    </div>
  </div>

  <script>
  // ===== Utilities =====
  const COLORS = { bg:'#a3d5ff', ground:'#7c4d2a', platform:'#8bd17c', spike:'#cc3333', player:'#264653', star:'#f1c40f', flag:'#ff7f50', doorClosed:'#555', doorOpen:'#2ecc71', text:'#111' };
  const width = 960, height = 540;

  function shuffle(arr){ const a=[...arr]; for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]];} return a; }
  function aabb(a,b){ return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y; }

  // ===== Level data =====
  const LEVELS = [
    { name:"Level 1 – Persegi Panjang",
      platforms:[{x:0,y:500,w:960,h:40},{x:100,y:420,w:180,h:20},{x:340,y:360,w:160,h:20},{x:580,y:300,w:200,h:20}],
      spikes:[{x:280,y:500,w:60,h:40}],
      stars:[{x:150,y:380},{x:380,y:320},{x:640,y:260}],
      start:{x:40,y:440}, quizFlag:{x:780,y:260,w:16,h:40}, exitDoor:{x:900,y:460,w:24,h:40},
      quiz:{ prompt:"Sebuah persegi panjang memiliki panjang 12 cm dan lebar 7 cm. Berapakah kelilingnya?",
             choices:[{text:"38 cm",correct:true},{text:"84 cm",correct:false},{text:"26 cm",correct:false},{text:"96 cm",correct:false}],
             explanation:"Keliling persegi panjang = 2 × (p + l) = 2 × (12 + 7) = 2 × 19 = 38 cm."}
    },
    { name:"Level 2 – Segitiga",
      platforms:[{x:0,y:500,w:960,h:40},{x:120,y:440,w:140,h:20},{x:300,y:380,w:160,h:20},{x:520,y:330,w:180,h:20},{x:760,y:290,w:140,h:20}],
      spikes:[{x:460,y:500,w:80,h:40},{x:700,y:500,w:60,h:40}],
      stars:[{x:170,y:400},{x:360,y:340},{x:800,y:250}],
      start:{x:40,y:440}, quizFlag:{x:780,y:250,w:16,h:40}, exitDoor:{x:900,y:460,w:24,h:40},
      quiz:{ prompt:"Sebuah segitiga memiliki alas 10 cm dan tinggi 8 cm. Berapakah luas segitiga tersebut?",
             choices:[{text:"40 cm²",correct:true},{text:"80 cm²",correct:false},{text:"18 cm²",correct:false},{text:"28 cm²",correct:false}],
             explanation:"Luas segitiga = 1/2 × alas × tinggi = 1/2 × 10 × 8 = 40 cm²."}
    },
    { name:"Level 3 – Jajar Genjang & Sudut",
      platforms:[{x:0,y:500,w:960,h:40},{x:160,y:430,w:140,h:20},{x:340,y:370,w:160,h:20},{x:560,y:320,w:160,h:20},{x:760,y:280,w:160,h:20}],
      spikes:[{x:250,y:500,w:60,h:40},{x:480,y:500,w:60,h:40},{x:720,y:500,w:60,h:40}],
      stars:[{x:200,y:390},{x:420,y:330},{x:780,y:240}],
      start:{x:40,y:440}, quizFlag:{x:800,y:240,w:16,h:40}, exitDoor:{x:900,y:460,w:24,h:40},
      quiz:{ prompt:"Jajar genjang memiliki alas 15 cm dan tinggi 6 cm. Berapa luasnya? (Tambahan: jumlah sudut dalam segiempat berapa derajat?)",
             choices:shuffle([{text:"90 cm² dan 360°",correct:true},{text:"90 cm² dan 180°",correct:false},{text:"45 cm² dan 360°",correct:false},{text:"96 cm² dan 270°",correct:false}]),
             explanation:"Luas jajar genjang = alas × tinggi = 15 × 6 = 90 cm². Jumlah sudut dalam segiempat = 360°."}
    }
  ];

  // ===== Game State =====
  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const state = {
    levelIndex:0, score:0, lives:3, paused:false, quizOpen:false, quizUnlocked:false,
    message:'Kumpulkan bintang dan capai gerbang!'
  };
  const player = { x:0,y:0,vx:0,vy:0,onGround:false,w:24,h:36 };
  let stars = [];
  const keys = { left:false, right:false, jump:false };

  function setLevel(i){
    state.levelIndex = i;
    const L = LEVELS[i];
    player.x=L.start.x; player.y=L.start.y; player.vx=0; player.vy=0; player.onGround=false;
    stars = L.stars.map(s=>({...s,collected:false}));
    state.quizUnlocked=false; state.paused=false; state.quizOpen=false;
    state.message=L.name+" – Sentuh bendera untuk kuis.";
    document.getElementById('levelName').textContent=L.name;
  }
  setLevel(0);

  // ===== Input: Keyboard =====
  window.addEventListener('keydown',e=>{
    if(e.code==='ArrowLeft' || e.code==='KeyA') keys.left=true;
    if(e.code==='ArrowRight'|| e.code==='KeyD') keys.right=true;
    if(['Space','ArrowUp','KeyW'].includes(e.code)) keys.jump=true;
    if(e.code==='KeyP') state.paused = !state.paused;
    if(e.code==='KeyR') resetGame();
  });
  window.addEventListener('keyup',e=>{
    if(e.code==='ArrowLeft' || e.code==='KeyA') keys.left=false;
    if(e.code==='ArrowRight'|| e.code==='KeyD') keys.right=false;
    if(['Space','ArrowUp','KeyW'].includes(e.code)) keys.jump=false;
  });

  // ===== Input: On-screen buttons =====
  function bindHold(btn, on, off){
    let hold=false; const down=()=>{hold=true; on();}; const up=()=>{hold=false; off&&off();};
    btn.addEventListener('touchstart',e=>{e.preventDefault();down();});
    btn.addEventListener('mousedown',e=>{e.preventDefault();down();});
    ['touchend','touchcancel','mouseup','mouseleave'].forEach(ev=>btn.addEventListener(ev,up));
  }
  bindHold(document.getElementById('leftBtn'), ()=>{keys.left=true;}, ()=>{keys.left=false;});
  bindHold(document.getElementById('rightBtn'),()=>{keys.right=true;},()=>{keys.right=false;});
  document.getElementById('jumpBtn').addEventListener('click',()=>{ keys.jump=true; setTimeout(()=>keys.jump=false,100); });
  document.getElementById('pauseBtn').addEventListener('click',()=> state.paused=!state.paused);
  document.getElementById('resetBtn').addEventListener('click', resetGame);

  // ===== Input: Touch drag on canvas (analog move), two-finger jump =====
  let lastTouchX=null; let activeTouches=0;
  canvas.addEventListener('touchstart',e=>{ activeTouches=e.touches.length; if(e.touches[0]) lastTouchX=e.touches[0].clientX;});
  canvas.addEventListener('touchmove',e=>{
    if(lastTouchX==null) return; const t=e.touches[0]; if(!t) return; const dx=t.clientX-lastTouchX; lastTouchX=t.clientX;
    player.x += dx * 0.4; // sensitivity
    clampPlayerX();
  }, {passive:true});
  canvas.addEventListener('touchend',e=>{
    // two-finger tap to jump
    if(activeTouches>=2){ keys.jump=true; setTimeout(()=>keys.jump=false,120); }
    activeTouches=e.touches.length; if(activeTouches===0) lastTouchX=null;
  });

  function clampPlayerX(){ if(player.x<0) player.x=0; if(player.x+player.w>width) player.x=width-player.w; }

  // ===== Game Loop =====
  let last=performance.now();
  function loop(now){
    const dt=Math.min(0.033,(now-last)/1000); last=now;
    if(!state.paused && !state.quizOpen) update(dt);
    render();
    requestAnimationFrame(loop);
  }
  requestAnimationFrame(loop);

  function resetPlayer(){ const L=LEVELS[state.levelIndex]; player.x=L.start.x; player.y=L.start.y; player.vx=0; player.vy=0; player.onGround=false; }
  function resetGame(){ setLevel(0); state.score=0; state.lives=3; state.paused=false; state.quizOpen=false; state.quizUnlocked=false; state.message='Game direset. Semangat!'; }

  function update(dt){
    const L=LEVELS[state.levelIndex];
    const acc=1200, maxSpeed=220, friction=900, gravity=1800, jumpSpeed=560;
    if(keys.left) player.vx-=acc*dt; if(keys.right) player.vx+=acc*dt;
    if(!keys.left && !keys.right){ if(player.vx>0) player.vx=Math.max(0,player.vx-friction*dt); else if(player.vx<0) player.vx=Math.min(0,player.vx+friction*dt); }
    player.vx=Math.max(-maxSpeed,Math.min(maxSpeed,player.vx));

    if(keys.jump && player.onGround){ player.vy=-jumpSpeed; player.onGround=false; }
    player.vy+=gravity*dt;

    let nextX=player.x+player.vx*dt, nextY=player.y+player.vy*dt;
    const pBox={x:nextX,y:nextY,w:player.w,h:player.h};

    player.onGround=false;
    for(const plat of L.platforms){
      const vBox={x:player.x,y:nextY,w:player.w,h:player.h};
      if(aabb(vBox,plat)){
        if(player.vy>0){ nextY=plat.y-player.h; player.vy=0; player.onGround=true; }
        else if(player.vy<0){ nextY=plat.y+plat.h; player.vy=0; }
      }
      const hBox={x:nextX,y:nextY,w:player.w,h:player.h};
      if(aabb(hBox,plat)){
        if(player.vx>0) nextX=plat.x-player.w; else if(player.vx<0) nextX=plat.x+plat.w; player.vx=0;
      }
    }

    if(nextX<0){nextX=0; player.vx=0;} if(nextX+player.w>width){nextX=width-player.w; player.vx=0;}
    if(nextY+player.h>height){
      state.lives=Math.max(0,state.lives-1);
      if(state.lives<=0){ state.message='Game Over! Tekan ↺ untuk ulang.'; state.paused=true; }
      resetPlayer(); return;
    }

    player.x=nextX; player.y=nextY;

    for(const s of stars){ if(!s.collected){ const d=Math.hypot((player.x+player.w/2)-s.x,(player.y+player.h/2)-s.y); if(d<24){ s.collected=true; state.score+=10; }}}

    for(const sp of L.spikes){ if(aabb({x:player.x,y:player.y,w:player.w,h:player.h}, sp)){ state.lives=Math.max(0,state.lives-1); resetPlayer(); return; }}

    const flagBox={x:L.quizFlag.x-8,y:L.quizFlag.y-8,w:L.quizFlag.w+16,h:L.quizFlag.h+16};
    if(aabb({x:player.x,y:player.y,w:player.w,h:player.h}, flagBox)) if(!state.quizUnlocked){ openQuiz(); }

    const door=L.exitDoor; const doorBox={x:door.x,y:door.y,w:door.w,h:door.h};
    if(aabb({x:player.x,y:player.y,w:player.w,h:player.h}, doorBox)){
      if(state.quizUnlocked){ if(state.levelIndex<LEVELS.length-1){ setLevel(state.levelIndex+1); state.message='Level berikutnya!'; } else { state.message='Selamat! Semua level selesai.'; state.paused=true; } }
    }
  }

  function drawStar(ctx,cx,cy,spikes,outerR,innerR){ let rot=Math.PI/2*3; let x=cx,y=cy; const step=Math.PI/spikes; ctx.beginPath(); ctx.moveTo(cx,cy-outerR); for(let i=0;i<spikes;i++){ x=cx+Math.cos(rot)*outerR; y=cy+Math.sin(rot)*outerR; ctx.lineTo(x,y); rot+=step; x=cx+Math.cos(rot)*innerR; y=cy+Math.sin(rot)*innerR; ctx.lineTo(x,y); rot+=step;} ctx.lineTo(cx,cy-outerR); ctx.closePath(); ctx.fillStyle=COLORS.star; ctx.fill(); }

  function render(){
    const L=LEVELS[state.levelIndex];
    ctx.fillStyle=COLORS.bg; ctx.fillRect(0,0,width,height);

    // HUD bar
    ctx.fillStyle='rgba(255,255,255,.65)'; ctx.fillRect(0,0,width,40);
    ctx.fillStyle=COLORS.text; ctx.font='16px ui-sans-serif,system-ui,-apple-system';
    ctx.fillText(L.name, 12, 26);
    ctx.fillText('Skor: '+state.score, 380, 26);
    ctx.fillText('Nyawa: '+state.lives, 480, 26);
    ctx.fillText('⏸/↺ di kanan bawah', 580, 26);

    ctx.fillStyle=COLORS.platform; for(const plat of L.platforms){ ctx.fillRect(plat.x,plat.y,plat.w,plat.h); }

    // spikes
    ctx.fillStyle=COLORS.spike; for(const sp of L.spikes){ const n=Math.max(1,Math.floor(sp.w/12)); for(let i=0;i<n;i++){ const x0=sp.x+(i*sp.w)/n; ctx.beginPath(); ctx.moveTo(x0, sp.y+sp.h); ctx.lineTo(x0+sp.w/n/2, sp.y); ctx.lineTo(x0+sp.w/n, sp.y+sp.h); ctx.closePath(); ctx.fill(); } }

    // stars
    for(const s of stars){ if(!s.collected) drawStar(ctx,s.x,s.y,5,10,4); }

    // flag
    ctx.fillStyle=COLORS.flag; ctx.fillRect(L.quizFlag.x, L.quizFlag.y-L.quizFlag.h, 4, L.quizFlag.h); ctx.fillRect(L.quizFlag.x+4, L.quizFlag.y-L.quizFlag.h, 12, 10);

    // door
    ctx.fillStyle = state.quizUnlocked ? COLORS.doorOpen : COLORS.doorClosed; ctx.fillRect(L.exitDoor.x, L.exitDoor.y, L.exitDoor.w, L.exitDoor.h);

    // player
    ctx.fillStyle=COLORS.player; ctx.fillRect(player.x,player.y,player.w,player.h);

    // footer message
    if(state.message){ ctx.fillStyle='rgba(0,0,0,.6)'; ctx.fillRect(0,height-36,width,36); ctx.fillStyle='#fff'; ctx.font='18px ui-sans-serif,system-ui,-apple-system'; ctx.fillText(state.message, 12, height-12); }
  }

  // ===== Quiz UI =====
  const quizModal=document.getElementById('quizModal');
  const qText=document.getElementById('qText');
  const qOpts=document.getElementById('qOpts');
  const qExp=document.getElementById('qExp');
  document.getElementById('closeQuiz').addEventListener('click', ()=>{ state.quizOpen=false; state.paused=false; quizModal.style.display='none'; });

  function openQuiz(){
    const L=LEVELS[state.levelIndex];
    state.quizOpen=true; state.paused=true;
    qText.textContent=L.quiz.prompt;
    qExp.textContent=L.quiz.explanation;
    qOpts.innerHTML='';
    shuffle(L.quiz.choices).forEach((c,i)=>{
      const btn=document.createElement('button'); btn.className='opt'; btn.textContent=c.text; btn.onclick=()=>submitAnswer(c.correct); qOpts.appendChild(btn);
    });
    quizModal.style.display='flex';
  }
  function submitAnswer(correct){
    if(correct){ state.message='Benar! Gerbang terbuka. Arahkan ke gerbang untuk lanjut.'; state.quizUnlocked=true; state.score+=20; }
    else{ state.message='Kurang tepat. Coba lagi – hati-hati rintangan!'; state.lives=Math.max(0,state.lives-1); }
    state.quizOpen=false; state.paused=false; quizModal.style.display='none';
  }

  // ===== HiDPI scaling (retina) for crisp canvas =====
  function scaleForDPR(){
    const dpr = Math.max(1, Math.min(2, window.devicePixelRatio || 1));
    // canvas style width is 100% via CSS; we keep internal buffer at 960x540 for stable physics
    // Optionally scale context for sharper text on high DPI
    ctx.setTransform(dpr,0,0,dpr,0,0); // not resizing buffer to avoid changing physics; small blur is acceptable
  }
  scaleForDPR();

  // Prevent page scroll on space/arrow when focused
  window.addEventListener('keydown',e=>{ if(['Space','ArrowUp','ArrowLeft','ArrowRight'].includes(e.code)) e.preventDefault(); }, {passive:false});
  </script>
</body>
</html>

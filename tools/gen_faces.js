// 陰影のあるリッチなオリジナル顔SVGを12種生成する。
// グラデーション(肌/髪/背景)・ハイライト・落ち影・チーク・光沢の目 で立体感を出す。
// 外部素材は一切使わず、全て手続き的に生成したオリジナル。
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', 'assets', 'images', 'faces');

// ---- パレット（多様な肌色・髪色・背景） ----
const SKINS = [
  { base: '#FFE0BD', shadow: '#EEBE94', light: '#FFF1DE' }, // 明るい
  { base: '#F6C89A', shadow: '#DCA06E', light: '#FFE6C8' },
  { base: '#E8B084', shadow: '#C88A5C', light: '#FBD3AE' },
  { base: '#C68A63', shadow: '#A66A45', light: '#DCA97F' }, // 褐色
  { base: '#8D5A3C', shadow: '#6E4028', light: '#A9744F' }, // 濃い
  { base: '#FFD9C0', shadow: '#EAB49A', light: '#FFEBDC' },
];
const HAIRS = [
  { base: '#3A2E2A', light: '#5C4A42', dark: '#241C19' }, // 黒〜こげ茶
  { base: '#6B4226', light: '#8A5A38', dark: '#4A2C18' }, // 茶
  { base: '#C9922E', light: '#E5B54E', dark: '#9C6E1E' }, // 金
  { base: '#B03A2E', light: '#D25A44', dark: '#872418' }, // 赤茶
  { base: '#2E3A56', light: '#48577C', dark: '#1D2540' }, // 濃紺
  { base: '#7A4F9E', light: '#9A6FC0', dark: '#5C3A78' }, // 紫
  { base: '#6E7B87', light: '#95A2AE', dark: '#515C66' }, // グレー
  { base: '#2E7D5B', light: '#45A379', dark: '#1E5C42' }, // 緑
];
const BGS = [
  ['#DFF1FF', '#AFD8F5'], ['#FFE7D6', '#FFC7A6'], ['#E6F7E9', '#BEE6C4'],
  ['#F1E6FF', '#D2B8F0'], ['#FFF3D6', '#FFDF9E'], ['#FDE2EC', '#F7B8CE'],
  ['#E2F5F5', '#B6E4E4'], ['#EDE9FF', '#C7BCF2'],
];
const MOUTHS = [
  // にっこり
  (c) => `<path d="M84 140 Q100 156 116 140" fill="none" stroke="${c}" stroke-width="4.5" stroke-linecap="round"/>`,
  // 大きめスマイル(歯)
  (c) => `<path d="M82 138 Q100 162 118 138 Z" fill="#fff" stroke="${c}" stroke-width="3.5" stroke-linejoin="round"/><path d="M82 138 Q100 150 118 138" fill="none" stroke="${c}" stroke-width="3.5" stroke-linecap="round"/>`,
  // 落ち着いた微笑み
  (c) => `<path d="M88 142 Q100 150 112 142" fill="none" stroke="${c}" stroke-width="4" stroke-linecap="round"/>`,
  // おすまし(小さめ)
  (c) => `<path d="M92 144 Q100 149 108 144" fill="none" stroke="${c}" stroke-width="4" stroke-linecap="round"/>`,
  // わらい(オー)
  (c) => `<ellipse cx="100" cy="144" rx="9" ry="11" fill="#B0603C"/><path d="M91 141 Q100 136 109 141" fill="${c === '#B0603C' ? '#8a4a2c' : c}"/>`,
];

function rng(seed) {
  let s = seed * 9301 + 49297;
  return () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
}
const pick = (arr, r) => arr[Math.floor(r() * arr.length) % arr.length];

// ---- 髪型 (顔の上・後ろ) ----
function hairBack(style, id) {
  // 顔の後ろに広がる毛（ロング/ボブ）。style により有無・形。
  switch (style) {
    case 'long':
      return `<path d="M44 96 Q40 172 66 182 Q54 150 58 104 Z" fill="url(#hairD${id})"/>
      <path d="M156 96 Q160 172 134 182 Q146 150 142 104 Z" fill="url(#hairD${id})"/>`;
    case 'bob':
      return `<path d="M46 98 Q44 150 70 158 Q60 130 60 104 Z" fill="url(#hairD${id})"/>
      <path d="M154 98 Q156 150 130 158 Q140 130 140 104 Z" fill="url(#hairD${id})"/>`;
    default:
      return '';
  }
}
function hairFront(style, id) {
  switch (style) {
    case 'spiky':
      return `<path d="M52 84 L58 52 L70 74 L82 44 L92 72 L100 40 L108 72 L118 44 L130 74 L142 52 L148 84 Q140 60 100 58 Q60 60 52 84 Z" fill="url(#hair${id})"/>
      <path d="M62 66 L70 74 M100 52 L100 66 M138 66 L130 74" stroke="url(#hairL${id})" stroke-width="3" stroke-linecap="round" fill="none"/>`;
    case 'sidepart':
      return `<path d="M52 88 Q54 44 100 42 Q150 44 150 92 Q150 70 110 66 Q106 52 96 52 Q64 54 60 86 Q56 80 52 88 Z" fill="url(#hair${id})"/>
      <path d="M96 54 Q118 58 128 74" stroke="url(#hairL${id})" stroke-width="3.5" stroke-linecap="round" fill="none"/>`;
    case 'bangs':
      return `<path d="M50 90 Q50 42 100 40 Q150 42 150 90 Q148 66 130 64 L128 84 L118 62 L112 84 L104 60 L96 84 L88 62 L82 84 L72 64 Q52 66 50 90 Z" fill="url(#hair${id})"/>`;
    case 'curly':
      return `<path d="M52 86 Q46 60 62 52 Q66 40 84 46 Q96 36 116 46 Q134 40 138 54 Q156 60 148 86 Q150 66 132 66 Q128 58 116 62 Q108 54 96 60 Q84 54 78 64 Q64 62 60 70 Q54 74 52 86 Z" fill="url(#hair${id})"/>
      <circle cx="62" cy="60" r="7" fill="url(#hair${id})"/><circle cx="138" cy="60" r="7" fill="url(#hair${id})"/><circle cx="100" cy="48" r="8" fill="url(#hair${id})"/>`;
    case 'buzz':
      return `<path d="M56 88 Q58 50 100 48 Q142 50 144 88 Q140 66 100 64 Q60 66 56 88 Z" fill="url(#hair${id})" opacity="0.96"/>`;
    default: // round
      return `<path d="M50 92 Q50 40 100 40 Q150 40 150 92 Q146 64 100 62 Q54 64 50 92 Z" fill="url(#hair${id})"/>
      <path d="M70 58 Q100 50 130 58" stroke="url(#hairL${id})" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.7"/>`;
  }
}

// ---- アクセサリ ----
function glasses() {
  return `<g opacity="0.92">
    <rect x="63" y="98" width="30" height="24" rx="9" fill="#ffffff" fill-opacity="0.18" stroke="#3a3a3a" stroke-width="3.5"/>
    <rect x="107" y="98" width="30" height="24" rx="9" fill="#ffffff" fill-opacity="0.18" stroke="#3a3a3a" stroke-width="3.5"/>
    <path d="M93 108 Q100 104 107 108" stroke="#3a3a3a" stroke-width="3.5" fill="none"/>
  </g>`;
}
function freckles(skinShadow) {
  const d = skinShadow;
  return `<g fill="${d}" opacity="0.55">
    <circle cx="74" cy="120" r="2"/><circle cx="80" cy="126" r="1.8"/><circle cx="70" cy="127" r="1.6"/>
    <circle cx="126" cy="120" r="2"/><circle cx="120" cy="126" r="1.8"/><circle cx="130" cy="127" r="1.6"/>
  </g>`;
}
function beard(hairBase) {
  return `<path d="M62 118 Q64 168 100 176 Q136 168 138 118 Q132 150 100 154 Q68 150 62 118 Z" fill="${hairBase}" opacity="0.9"/>`;
}

function buildFace(i) {
  const r = rng(i + 1);
  const skin = pick(SKINS, r);
  const hair = pick(HAIRS, r);
  const bg = pick(BGS, r);
  const frontStyles = ['round', 'spiky', 'sidepart', 'bangs', 'curly', 'buzz'];
  const front = frontStyles[i % frontStyles.length];
  const back = (i % 3 === 0) ? 'long' : (i % 3 === 1) ? 'bob' : 'none';
  const mouth = MOUTHS[i % MOUTHS.length];
  const hasGlasses = i % 4 === 0;
  const hasFreckles = i % 5 === 2;
  const hasBeard = (front === 'buzz' || front === 'spiky') && i % 2 === 0;
  const eyeColor = pick(['#3B2A1E', '#4A3524', '#2E4A63', '#3A5A3A', '#5A3A63'], r);

  const grads = `
  <defs>
    <radialGradient id="bg${i}" cx="42%" cy="34%" r="75%">
      <stop offset="0%" stop-color="${bg[0]}"/>
      <stop offset="100%" stop-color="${bg[1]}"/>
    </radialGradient>
    <radialGradient id="skin${i}" cx="40%" cy="34%" r="72%">
      <stop offset="0%" stop-color="${skin.light}"/>
      <stop offset="60%" stop-color="${skin.base}"/>
      <stop offset="100%" stop-color="${skin.shadow}"/>
    </radialGradient>
    <linearGradient id="hair${i}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="${hair.light}"/>
      <stop offset="55%" stop-color="${hair.base}"/>
      <stop offset="100%" stop-color="${hair.dark}"/>
    </linearGradient>
    <linearGradient id="hairD${i}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="${hair.base}"/>
      <stop offset="100%" stop-color="${hair.dark}"/>
    </linearGradient>
    <linearGradient id="hairL${i}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="${hair.light}"/>
      <stop offset="100%" stop-color="${hair.base}"/>
    </linearGradient>
    <radialGradient id="cheek${i}" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#FF8FA3" stop-opacity="0.55"/>
      <stop offset="100%" stop-color="#FF8FA3" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="iris${i}" cx="50%" cy="38%" r="60%">
      <stop offset="0%" stop-color="${eyeColor}" stop-opacity="0.6"/>
      <stop offset="70%" stop-color="${eyeColor}"/>
      <stop offset="100%" stop-color="#1a1410"/>
    </radialGradient>
    <radialGradient id="vig${i}" cx="50%" cy="50%" r="50%">
      <stop offset="70%" stop-color="#000000" stop-opacity="0"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0.10"/>
    </radialGradient>
  </defs>`;

  // 目（光沢入り）
  const eye = (cx) => `
    <ellipse cx="${cx}" cy="112" rx="11" ry="12.5" fill="#ffffff"/>
    <ellipse cx="${cx}" cy="112" rx="11" ry="12.5" fill="url(#vig${i})"/>
    <circle cx="${cx}" cy="113" r="6.6" fill="url(#iris${i})"/>
    <circle cx="${cx}" cy="113" r="3" fill="#140f0b"/>
    <circle cx="${cx - 2.4}" cy="109.5" r="2.2" fill="#ffffff"/>
    <circle cx="${cx + 2}" cy="115.5" r="1" fill="#ffffff" opacity="0.7"/>
    <path d="M${cx - 12} 104 Q${cx} 98 ${cx + 12} 104" fill="none" stroke="${hair.dark}" stroke-width="3.4" stroke-linecap="round"/>`;

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  ${grads}
  <circle cx="100" cy="100" r="98" fill="url(#bg${i})"/>
  ${hairBack(back, i)}
  <!-- 首と落ち影 -->
  <ellipse cx="100" cy="188" rx="34" ry="26" fill="${skin.shadow}"/>
  <ellipse cx="100" cy="150" rx="52" ry="30" fill="#000000" opacity="0.06"/>
  <!-- 耳 -->
  <ellipse cx="50" cy="118" rx="10" ry="13" fill="url(#skin${i})"/>
  <ellipse cx="150" cy="118" rx="10" ry="13" fill="url(#skin${i})"/>
  <ellipse cx="50" cy="118" rx="4" ry="6" fill="${skin.shadow}" opacity="0.6"/>
  <ellipse cx="150" cy="118" rx="4" ry="6" fill="${skin.shadow}" opacity="0.6"/>
  <!-- 顔 -->
  <path d="M52 108 Q52 62 100 60 Q148 62 148 108 Q148 150 100 162 Q52 150 52 108 Z" fill="url(#skin${i})"/>
  <!-- 頬の陰影 -->
  <path d="M100 60 Q148 62 148 108 Q148 150 100 162 Q126 140 128 108 Q128 74 100 60 Z" fill="${skin.shadow}" opacity="0.18"/>
  ${hairFront(front, i)}
  <!-- チーク -->
  <ellipse cx="74" cy="128" rx="13" ry="9" fill="url(#cheek${i})"/>
  <ellipse cx="126" cy="128" rx="13" ry="9" fill="url(#cheek${i})"/>
  ${hasFreckles ? freckles(skin.shadow) : ''}
  <!-- 鼻 -->
  <path d="M100 116 Q96 128 100 130 Q104 128 100 116" fill="${skin.shadow}" opacity="0.4"/>
  <ellipse cx="100" cy="130" rx="4" ry="2.4" fill="${skin.shadow}" opacity="0.35"/>
  ${eye(78)}
  ${eye(122)}
  ${hasGlasses ? glasses() : ''}
  ${mouth('#B0603C')}
  ${hasBeard ? beard(hair.base) : ''}
  <!-- ハイライト(額) -->
  <ellipse cx="82" cy="82" rx="14" ry="8" fill="#ffffff" opacity="0.16"/>
</svg>`;
  return svg.replace(/\n\s+/g, '\n');
}

for (let i = 1; i <= 12; i++) {
  const svg = buildFace(i);
  fs.writeFileSync(path.join(OUT, `face${i}.svg`), svg, 'utf8');
  console.log(`wrote face${i}.svg (${svg.length} bytes)`);
}
console.log('done');

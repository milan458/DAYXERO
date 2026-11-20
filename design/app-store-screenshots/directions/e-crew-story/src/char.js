/* DayXero crew: Xero, Jelli and Glim, ported one to one from the designer's canvas component Char.dc.html
   (who = xero | jelli | glim, expr = happy | sleepy | cheer, size = width in px; the box is size x 1.1 size).
   Same viewBox (200 x 220), same paths and colours. The animations are dropped for a still frame: every element sits at
   its rest pose, and Glim's two pulsing glows sit at .4, the middle of their .25 to .55 pulse.
   Usage: DXCHAR({ who: 'jelli', expr: 'cheer', size: 300 }) returns an HTML string (a sized div holding the SVG). */
(function () {
  'use strict';
  const E = {
    xero: {
      happy: { eyes: 'M72 92 a9 12 0 1 0 18 0 a9 12 0 1 0 -18 0 M110 92 a9 12 0 1 0 18 0 a9 12 0 1 0 -18 0', fill: '#201D2E', sw: 1, glints: 'M80 86 a3 3 0 1 0 6 0 a3 3 0 1 0 -6 0 M118 86 a3 3 0 1 0 6 0 a3 3 0 1 0 -6 0', mouth: 'M88 116 Q100 128 112 116', mf: 'none' },
      sleepy: { eyes: 'M70 94 Q81 102 92 94 M108 94 Q119 102 130 94', fill: 'none', sw: 5, glints: '', mouth: 'M92 120 Q100 125 108 120', mf: 'none' },
      cheer: { eyes: 'M70 98 Q81 84 92 98 M108 98 Q119 84 130 98', fill: 'none', sw: 5, glints: '', mouth: 'M84 112 Q100 140 116 112 Z', mf: '#201D2E' }
    },
    jelli: {
      happy: { eyes: 'M74 86 a6 7 0 1 0 12 0 a6 7 0 1 0 -12 0 M114 86 a6 7 0 1 0 12 0 a6 7 0 1 0 -12 0', fill: '#201D2E', sw: 1, mouth: 'M90 100 Q100 110 110 100', mf: 'none' },
      sleepy: { eyes: 'M70 88 Q80 96 90 88 M110 88 Q120 96 130 88', fill: 'none', sw: 5, mouth: 'M94 102 Q100 106 106 102', mf: 'none' },
      cheer: { eyes: 'M70 92 Q80 80 90 92 M110 92 Q120 80 130 92', fill: 'none', sw: 5, mouth: 'M86 98 Q100 120 114 98 Z', mf: '#201D2E' }
    },
    glim: {
      happy: { eyes: 'M78 86 a6 7 0 1 0 12 0 a6 7 0 1 0 -12 0 M110 86 a6 7 0 1 0 12 0 a6 7 0 1 0 -12 0', fill: '#FFF7EE', sw: 1, mouth: 'M90 106 Q100 114 110 106', mf: 'none' },
      sleepy: { eyes: 'M74 90 Q84 96 94 90 M106 90 Q116 96 126 90', fill: 'none', sw: 5, mouth: 'M94 108 Q100 112 106 108', mf: 'none' },
      cheer: { eyes: 'M74 94 Q84 82 94 94 M106 94 Q116 82 126 94', fill: 'none', sw: 5, mouth: 'M88 104 Q100 124 112 104 Z', mf: '#FFF7EE' }
    }
  };
  const LABEL = { xero: 'Xero, the coral guide', jelli: 'Jelli, the pink jellyfish', glim: 'Glim, the purple firefly' };

  function xero(e, cheer) {
    const armL = cheer ? 'M42 112 Q16 96 18 66' : 'M40 118 Q18 130 20 156';
    const armR = cheer ? 'M158 112 Q184 96 182 66' : 'M160 118 Q182 130 180 156';
    return `<g>
<ellipse cx="78" cy="198" rx="17" ry="9" fill="#E8603C"/>
<ellipse cx="122" cy="198" rx="17" ry="9" fill="#E8603C"/>
<path d="${armL}" fill="none" stroke="#FF7A55" stroke-width="15" stroke-linecap="round"/>
<path d="${armR}" fill="none" stroke="#FF7A55" stroke-width="15" stroke-linecap="round"/>
<path d="M100 18 C152 18 170 70 168 120 C166 172 140 200 100 200 C60 200 34 172 32 120 C30 70 48 18 100 18Z" fill="#FF7A55"/>
<path d="M100 18 C152 18 170 70 168 120 C166 172 140 200 100 200 C128 186 150 160 152 116 C154 66 136 30 100 18Z" fill="#E8603C" opacity=".35"/>
<ellipse cx="68" cy="58" rx="12" ry="22" transform="rotate(-24 68 58)" fill="#FFFFFF" opacity=".4"/>
<ellipse cx="100" cy="152" rx="28" ry="33" fill="#DCEBFF"/>
<path d="M73 160 Q100 140 127 160 Q127 176 116 184 L84 184 Q73 176 73 160Z" fill="#8FD9A8"/>
<path d="M80 172 Q100 162 120 172 Q116 182 100 185 Q84 182 80 172Z" fill="#FFD966"/>
<ellipse cx="62" cy="120" rx="11" ry="6.5" fill="#FFB3A7"/>
<ellipse cx="138" cy="120" rx="11" ry="6.5" fill="#FFB3A7"/>
<path d="${e.eyes}" fill="${e.fill}" stroke="#201D2E" stroke-width="${e.sw}" stroke-linecap="round"/>
<path d="${e.glints || ''}" fill="#FFFFFF"/>
<path d="${e.mouth}" fill="${e.mf}" stroke="#201D2E" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
</g>`;
  }
  function jelli(e) {
    return `<g>
<circle cx="160" cy="40" r="7" fill="none" stroke="#FFFFFF" stroke-width="3" opacity=".8"/>
<circle cx="176" cy="66" r="4" fill="none" stroke="#FFFFFF" stroke-width="2.5" opacity=".8"/>
<g fill="none" stroke="#FF8FA3" stroke-width="9" stroke-linecap="round">
<path d="M58 122 C52 146 66 160 58 184 C54 196 60 204 64 206"/>
<path d="M80 126 C76 152 90 168 82 196"/>
<path d="M100 126 C96 154 108 172 100 204"/>
<path d="M120 126 C116 152 130 168 122 196"/>
<path d="M142 122 C136 146 150 160 142 184 C138 196 144 204 148 206"/>
</g>
<path d="M28 120 C28 58 62 26 100 26 C138 26 172 58 172 120 Q152 134 132 122 Q116 136 100 122 Q84 136 68 122 Q48 134 28 120Z" fill="#FF8FA3"/>
<path d="M100 26 C138 26 172 58 172 120 Q160 128 148 124 C152 80 134 44 100 26Z" fill="#E86A86" opacity=".3"/>
<circle cx="66" cy="62" r="8" fill="#FFC2CC"/><circle cx="128" cy="50" r="5" fill="#FFC2CC"/><circle cx="148" cy="80" r="6" fill="#FFC2CC"/><circle cx="52" cy="92" r="4" fill="#FFC2CC"/><circle cx="96" cy="44" r="4" fill="#FFC2CC"/>
<ellipse cx="66" cy="104" rx="10" ry="6" fill="#FF6F8F" opacity=".55"/>
<ellipse cx="134" cy="104" rx="10" ry="6" fill="#FF6F8F" opacity=".55"/>
<path d="${e.eyes}" fill="${e.fill}" stroke="#201D2E" stroke-width="${e.sw}" stroke-linecap="round"/>
<path d="${e.mouth}" fill="${e.mf}" stroke="#201D2E" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
</g>`;
  }
  function glim(e) {
    return `<g>
<circle cx="100" cy="158" r="62" fill="#FFD966" opacity=".4"/>
<ellipse cx="48" cy="86" rx="36" ry="22" transform="rotate(-28 48 86)" fill="#DCE6FF" stroke="#B9C8F5" stroke-width="3" opacity=".95"/>
<ellipse cx="152" cy="86" rx="36" ry="22" transform="rotate(28 152 86)" fill="#DCE6FF" stroke="#B9C8F5" stroke-width="3" opacity=".95"/>
<path d="M82 52 L68 18 M118 52 L132 18" stroke="#5B3FD0" stroke-width="5" stroke-linecap="round"/>
<circle cx="68" cy="16" r="12" fill="#FFD966" opacity=".4"/><circle cx="68" cy="16" r="8" fill="#FFD966"/>
<circle cx="132" cy="16" r="12" fill="#FFD966" opacity=".4"/><circle cx="132" cy="16" r="8" fill="#FFD966"/>
<ellipse cx="100" cy="160" rx="42" ry="40" fill="#FFD966"/>
<path d="M62 150 Q100 162 138 150 M60 170 Q100 182 140 170 M68 188 Q100 198 132 188" fill="none" stroke="#E3AE2F" stroke-width="6" stroke-linecap="round"/>
<path d="M56 116 q-18 6 -20 24 M144 116 q18 6 20 24" fill="none" stroke="#7B5CE0" stroke-width="11" stroke-linecap="round"/>
<circle cx="100" cy="90" r="48" fill="#7B5CE0"/>
<path d="M100 42 A48 48 0 0 1 100 138 A40 48 0 0 0 100 42Z" fill="#5B3FD0" opacity=".45"/>
<ellipse cx="74" cy="66" rx="9" ry="14" transform="rotate(-24 74 66)" fill="#FFFFFF" opacity=".3"/>
<ellipse cx="72" cy="104" rx="9" ry="5.5" fill="#FF9EC0" opacity=".7"/>
<ellipse cx="128" cy="104" rx="9" ry="5.5" fill="#FF9EC0" opacity=".7"/>
<path d="${e.eyes}" fill="${e.fill}" stroke="#FFF7EE" stroke-width="${e.sw}" stroke-linecap="round"/>
<path d="${e.mouth}" fill="${e.mf}" stroke="#FFF7EE" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
</g>`;
  }

  window.DXCHAR = function ({ who = 'xero', expr = 'happy', size = 300 } = {}) {
    const e = (E[who] || E.xero)[expr] || E[who].happy;
    const body = who === 'jelli' ? jelli(e) : who === 'glim' ? glim(e) : xero(e, expr === 'cheer');
    return `<div style="width: ${size}px; height: ${Math.round(size * 1.1)}px; position: relative">` +
      `<svg role="img" aria-label="${LABEL[who]}" width="100%" height="100%" viewBox="0 0 200 220" style="overflow: visible; display: block">` +
      `<ellipse cx="100" cy="210" rx="52" ry="7" fill="#201D2E" opacity=".12"/>${body}</svg></div>`;
  };
})();

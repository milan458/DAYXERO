/* DayXero App Store screenshots, Direction E, iPad and iPhone Duo sets: the device around a real capture.
   DXDEVICE(kind, a) returns the markup for one device, absolutely placed on the 1320-wide stage of height H.
     kind  ipad | duo-cover | duo-inner (the set being rendered; the screen keeps that capture's exact aspect)
     a     the <x-device> attributes:
           src     capture name in ../real-<kind>/ (no .png)      alt   text for the image
           top     the device's top edge on the stage (px), or "H-460" for 460 px above the stage's bottom edge
           bottom  gap from the stage's bottom edge (px; negative runs it off the bottom). With top, sets the height.
           h       the device's height (px), when bottom isn't given
           cx | left | right   where it sits across (centre x, or an edge gap)
           rot     a slight tilt in degrees                         shade  shadow colour, as "r,g,b"
           dark    true for a dark bezel and screen backing
   No Dynamic Island is drawn: the iPad has none, and the iPhone Duo's displays carry the status bar the captures show. */
(function (root) {
  'use strict';
  var SCREEN = { ipad: [2064, 2752], 'duo-cover': [1398, 2034], 'duo-inner': [2007, 2853] };
  var BEZEL = { ipad: [24, 64], 'duo-cover': [18, 92], 'duo-inner': [20, 70] };   // [bezel px, outer corner px]
  function DXDEVICE(kind, a, H) {
    var s = SCREEN[kind], b = BEZEL[kind], pad = b[0], R = b[1];
    var top = String(a.top).charAt(0) === 'H' ? H + Number(String(a.top).slice(1)) : Number(a.top), h;   // "H-460": 460 above the bottom edge
    if (a.bottom != null) h = H - top - Number(a.bottom); else h = Number(a.h);
    var sh = h - 2 * pad, sw = Math.round(sh * s[0] / s[1]), w = sw + 2 * pad;
    var left = a.cx != null ? Math.round(Number(a.cx) - w / 2) : a.left != null ? Number(a.left) : 1320 - Number(a.right) - w;
    var shade = a.shade || '32,29,46', dark = a.dark === 'true';
    return '<div style="position: absolute; left: ' + left + 'px; top: ' + top + 'px; width: ' + w + 'px; height: ' + h + 'px; box-sizing: border-box; padding: ' + pad + 'px; border-radius: ' + R + 'px; background: ' + (dark ? '#15102E' : '#201D2E') +
      '; box-shadow: 0 40px 90px rgba(' + shade + ',.30)' + (a.rot ? '; transform: rotate(' + a.rot + 'deg)' : '') + '">' +
      '<div style="position: relative; width: 100%; height: 100%; border-radius: ' + (R - pad) + 'px; overflow: hidden; background: ' + (dark ? '#0F1B33' : '#FBF7F1') + '">' +
      '<img src="../real-' + kind + '/' + a.src + '.png" alt="' + (a.alt || '') + '" style="display: block; width: ' + sw + 'px; height: ' + sh + 'px">' +
      '</div></div>';
  }
  /* DXLIFT(kind, a): a row lifted out of a capture, as frames 4 and 7 do. The crop is per set, in capture pixels:
     a.ipad / a['duo-cover'] / a['duo-inner'] = "x,y,w,h". a.left, a.top place it; a.w is its width on the stage.
     A set with no crop draws nothing. */
  function DXLIFT(kind, a) {
    var c = a[kind]; if (!c) return '';
    c = c.split(',').map(Number);
    var k = Number(a.w) / c[2], s = SCREEN[kind];
    return '<div style="position: absolute; left: ' + a.left + 'px; top: ' + a.top + 'px; width: ' + a.w + 'px; height: ' + Math.round(c[3] * k) + 'px; border-radius: ' + (a.r || 36) + 'px; overflow: hidden; background: #FBF7F1; box-shadow: 0 30px 60px rgba(' + (a.shade || '32,29,46') + ',.30), 0 8px 18px rgba(' + (a.shade || '32,29,46') + ',.16)">' +
      '<img src="../real-' + kind + '/' + a.src + '.png" alt="' + (a.alt || '') + '" style="position: absolute; left: ' + Math.round(-c[0] * k) + 'px; top: ' + Math.round(-c[1] * k) + 'px; width: ' + Math.round(s[0] * k) + 'px; height: ' + Math.round(s[1] * k) + 'px; max-width: none">' +
      '</div>';
  }
  root.DXDEVICE = DXDEVICE; root.DXLIFT = DXLIFT;
})(typeof window !== 'undefined' ? window : globalThis);

<div class="typesetter">
<h1>Factorio Typesetter</h1>
<div class="form" style="max-width: 40rem">
  <label for="message">Text</label>
  <textarea id="message" rows="6">ABCDEFGHIJKLM
NOPQRSTUVWXYZ
abcdefghijklm
nopqrstuvwxyz
1234567890.,-</textarea>
  <label for="select-font">Font</label>
  <select id="select-font" onchange="typesetter.onFontChange()">
  </select>
  <div id="font-details"></div>
  <label>Kerning</label>
  <div style="display:flex;">
    <input type="radio" name="kerning" id="use-metrics" value="metrics" checked
      style="flex:0;height:1.5rem;margin-left:0.5rem;">
    <label for="use-metrics" style="flex:1;margin-left:1rem">
      Usefont metrics (snap-to-grid bounding box)
    </label>
  </div>
  <div style="display:flex;">
    <input type="radio" name="kerning" id="use-fixed" value="fixed" style="flex:0;height:1.5rem;margin-left:0.5rem;">
    <label for="use-fixed" style="flex:1;margin-left:1rem">
      Use fixed width and height
    </label>
    <input type="number" id="fixed-width" value="8" style="flex: 0">
    <input type="number" id="fixed-height" value="10" style="flex: 0">
  </div>
  <label for="letter-spacing">Letter spacing (default 0)</label>
  <input type="number" id="letter-spacing" value="0">
  <label for="line-spacing">Line spacing (default 0)</label>
  <input type="number" id="line-spacing" value="0">
  <button onclick="typesetter.createBlueprint()">Create blueprint</button>
</div>
<br />
<div class="form">
  <label for="blueprint">Blueprint string</label>
  <textarea id="blueprint" rows="6"></textarea>
  <label for="blueprint-preview">Blueprint preview</label>
  <div id="blueprint-preview"></div>
</div>
</div>